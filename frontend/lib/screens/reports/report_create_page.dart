import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/personal_reports_api.dart';
import 'package:frontend/api/reports_api.dart';
import 'package:frontend/api/schedule_api.dart';
import 'package:frontend/exceptions/user_role.dart';
import 'package:frontend/models/member_model.dart';
import 'package:frontend/models/reports/personal_report_entry_model.dart';
import 'package:frontend/models/reports/personal_report_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/models/reports/team_report_entry_model.dart';
import 'package:frontend/models/reports/team_report_model.dart';
import 'package:frontend/models/reports/team_summary_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/team_info_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/reports/personal_report_provider.dart';
import 'package:frontend/providers/reports/team_report_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/utils/image_helper.dart';
import 'package:frontend/widgets/common/avatar.dart';
import 'package:frontend/widgets/dialogs/confirm_dialog.dart';
import 'package:frontend/widgets/pickers/member_multi_selector_modal.dart';
import 'package:frontend/widgets/pickers/team_picker_sheet.dart';
import 'package:frontend/widgets/schedule_widget/site_selector_modal.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';
import 'package:frontend/widgets/schedule_widget/work_selector_model.dart';


enum ReportTarget { personal, team }

class ReportsCreatePage extends ConsumerStatefulWidget {
  const ReportsCreatePage({
    super.key,
    this.initialPersonal,
    this.initialTeam,
  }) : assert(initialPersonal == null || initialTeam == null,
       'initialPersonal と initialTeam は同時に渡せません');

  final PersonalReportModel? initialPersonal;
  final TeamReportModel? initialTeam;

  @override
  ConsumerState<ReportsCreatePage> createState() => _ReportsCreatePageState();
}

class _ReportsCreatePageState extends ConsumerState<ReportsCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // ------- 基本情報 -------
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  ReportTarget _target = ReportTarget.personal;
  String? _teamId;     // 後で選択結果を入れる
  String? _teamName;   // 表示用
  final _noteCtrl = TextEditingController();

  // ------- 明細（行） -------
  final List<_EntryRow> _rows = <_EntryRow>[];

  bool _saving = false;

  ReportStatus? _existingPersonalStatus;

  // 既存の「当日&自分の個人日報」をプレフィルした時に入れておく
  String? _existingPersonalId;   // 既存があれば UUID、無ければ null

  // 既存チーム日報
  String? _existingTeamId;

  // ドラフト比較用のスナップショット（ある時だけ比較対象にする）
  String? _baselineSig;

  late final VoidCallback _noteListener;

  @override
  void initState() {
    super.initState();
    _rows.add(_EntryRow());

    if (widget.initialTeam != null) {
      // ★ チーム日報の指定がある → それを画面に反映
      _prefillFromGivenTeam(widget.initialTeam!);
    } else if (widget.initialPersonal != null) {
      // ★ 個人日報の指定がある → それを画面に反映
      _prefillFromGivenPersonal(widget.initialPersonal!);
    } else {
      // ★ ない → 従来どおり「今日の自分の日報」を読む
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromPersonal(_date);
      });
    }

    _noteListener = () => setState(() {});
    _noteCtrl.addListener(_noteListener);

    // === ここから追加（閲覧権限ガード）========================
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Team 詳細で権限が無ければ戻す
      if (widget.initialTeam != null &&
          !(widget.initialTeam!.permissions.canViewDetail)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('権限がありません')));
        Navigator.of(context).pop();
        return;
      }
      // Personal 詳細で権限が無ければ戻す
      if (widget.initialPersonal != null &&
          !(widget.initialPersonal!.permissions.canViewDetail)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('権限がありません')));
        Navigator.of(context).pop();
      }
    });
    // ==========================================================
  }

  @override
  void dispose() {
    _noteCtrl.removeListener(_noteListener);
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _hasBaseline => _baselineSig != null;
  bool get _changedFromBaseline =>
      _hasBaseline && _baselineSig != _currentSignature();

  String _currentSignature() {
    final head = (_noteCtrl.text).trim();

    final items = _rows.map((r) {
      final siteId = r.site?.id ?? '';
      final wcId   = r.workCategory?.id ?? '';
      final sh = r.start.hour.toString().padLeft(2, '0');
      final sm = r.start.minute.toString().padLeft(2, '0');
      final eh = r.end.hour.toString().padLeft(2, '0');
      final em = r.end.minute.toString().padLeft(2, '0');
      final note = (r.note ?? '').trim();

      // チームのときはメンバーも差分対象
      if (_target == ReportTarget.team) {
        final mids = (r.members.map((m) => m.id).toList()..sort()).join(',');
        return 'T|$siteId|$wcId|$sh$sm-$eh$em|$note|$mids';
      } else {
        return 'P|$siteId|$wcId|$sh$sm-$eh$em|$note';
      }
    }).toList()
      ..sort();

    return '$head\n${items.join('\n')}';
  }

  void _captureBaseline() {
    _baselineSig = _currentSignature();
  }

  // API で使う entry payload（update 用）
  List<Map<String, dynamic>> _buildPersonalEntryPayloads() {
    String t(TimeOfDay x) =>
        '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
    return _rows.map((r) => {
          'site_id'         : r.site!.id,
          'work_category_id': r.workCategory?.id,
          'start_time'      : t(r.start),
          'end_time'        : t(r.end),
          'note'            : (r.note ?? '').trim(),
        }).toList();
  }

  void _prefillFromGivenPersonal(PersonalReportModel pr) {
    setState(() {
      _target = ReportTarget.personal;                 // 個人固定
      _date   = DateUtils.dateOnly(pr.date);
      _existingPersonalId = pr.id;
      _existingPersonalStatus = pr.status;
      _noteCtrl.text = pr.note ?? '';

      _rows
        ..clear()
        ..addAll(pr.entries.map((e) => _EntryRow()
          ..site         = e.site
          ..workCategory = e.workCategory
          ..start        = e.startTime
          ..end          = e.endTime
          ..note         = e.note
        ));

      if (_rows.isEmpty) _rows.add(_EntryRow());

      if (pr.status != ReportStatus.locked) {
        _captureBaseline();
      } else {
        _baselineSig = null;
      }
    });
  }

  void _prefillFromGivenTeam(TeamReportModel tr) {
    setState(() {
      _target   = ReportTarget.team;
      _date     = DateUtils.dateOnly(tr.date);
      _teamId   = tr.team.id;     // TeamSummaryModel を想定
      _teamName = tr.team.name;
      _noteCtrl.text = tr.note ?? '';

      _rows.clear();

      // ① (site, workCategory, start, end, note) でグルーピングして members を集約
      final Map<String, _EntryRow> grouped = {};
      String k(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

      for (final e in tr.entries) {
        final siteId = e.site.id ?? '';
        final wcId   = e.workCategory?.id?.toString() ?? 'null';
        final st     = e.startTime;
        final et     = e.endTime;
        final note   = (e.note ?? '').trim();

        final key = '$siteId|$wcId|${k(st)}|${k(et)}|$note';

        var row = grouped[key];
        if (row == null) {
          row = _EntryRow(
            members: [e.member],
            start  : st,
            end    : et,
          )
            ..site         = e.site
            ..workCategory = e.workCategory
            ..note         = note.isEmpty ? null : note;
          grouped[key] = row;
          _rows.add(row);
        } else {
          if (!row.members.any((m) => m.id == e.member.id)) {
            row.members.add(e.member);
          }
        }
      }

      if (_rows.isEmpty) {
        _rows.add(_EntryRow());
      }

      // 個人用の既存IDやドラフト判定は関係なし
      _existingPersonalId = null;
      _baselineSig = null;

      _existingTeamId = tr.id;
      _captureBaseline();
    });
  }

  // 権限ヘルパー（どこからでも使えるように）
  bool get _isPrivilegedUser {
    final u = ref.read(userProvider);
    return (u?.isAdmin ?? false) ||
          (u?.isManager ?? false) ||
          ((u?.teams ?? const []).any((t) => t.role == 'leader'));
  }

  bool get _canApproveCurrentPersonal {
    return widget.initialPersonal?.permissions.canApprove ?? false;
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      // ログイン直後など、UserNotifier へのセット前を想定
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ---- 権限判定 ----
    final bool isAdmin = user.isAdmin;
    final bool isManager = user.isManager;
    final bool isTeamLeader = user.teams.any((t) => t.role == 'leader');
    final bool canSelectTeam = isAdmin || isManager || isTeamLeader;

    final bool isPrivileged = isAdmin || isManager || isTeamLeader;

    final bool viewingExistingPersonal = widget.initialPersonal != null;
    final bool viewingExistingTeam     = widget.initialTeam != null;

    // 追加: 個人日報の承認権限（サーバ計算）と pending 状態
    final bool canApprovePersonal =
        widget.initialPersonal?.permissions.canApprove ?? false;

    final bool isPersonalPending =
        viewingExistingPersonal && _existingPersonalStatus == ReportStatus.pending;

    // 権限で team が不可なら実質 personal 固定
    final ReportTarget effectiveTarget = canSelectTeam ? _target : ReportTarget.personal;
    final bool showMember = effectiveTarget == ReportTarget.team;

    Widget _buildTypeSelector() {
    final valueText = _target == ReportTarget.personal
        ? '個人'
        : (_teamName ?? 'チーム未選択');

    if (viewingExistingPersonal) {
      // ★ 詳細モードでは種類は固定表示＆タップ不可
      return const LabelWithButtonRow(label: '種類', value: '個人', onTap: null);
    }

    if (viewingExistingTeam) {
      // ★ 詳細モード：チーム名を固定表示
      return LabelWithButtonRow(label: '種類', value: _teamName ?? 'チーム', onTap: null);
    }

    if (isAdmin || isManager) {
      return LabelWithButtonRow(
        label: '種類',
        value: valueText,
        onTap: _pickAdminTeam,
      );
    } else if (isTeamLeader) {
      return LabelWithButtonRow(
        label: '種類',
        value: valueText,
        onTap: _pickTeam,
      );
    } else {
      return LabelWithButtonRow(
        label: '種類',
        value: '個人', // 固定表示
        onTap: null,
      );
    }
  }

  String? _actionLabel() {
    if (effectiveTarget == ReportTarget.team) {
      // 既存 submitted あり → 権限がある & 変更がある時だけ「更新」
      if (_existingTeamId != null) {
        final canEditTeam = widget.initialTeam?.permissions.canDelete ?? false;
        if (!canEditTeam) return null;
        return _changedFromBaseline ? '更新' : null;
      }
      // 新規チーム日報 → 「提出」
      return '提出';
    } else {
      // ===== 個人日報 =====
      if (_existingPersonalId != null) {
        if (_existingPersonalStatus == ReportStatus.locked) return null;

        // --- pending ---
        if (_existingPersonalStatus == ReportStatus.pending) {
          if (canApprovePersonal) {
            // 承認者（admin / manager / どこかのリーダー）
            return _changedFromBaseline ? '訂正' : '承認';
          } else {
            // 非承認者
            return _changedFromBaseline ? '変更申請' : null;
          }
        }

        // --- draft ---
        if (_existingPersonalStatus == ReportStatus.draft) {
          if (!_changedFromBaseline) {
            // 変更なしでも「提出」を表示
            return '提出';
          }
          // 変更あり：権限者は「提出」、一般は「変更申請」
          return isPrivileged ? '提出' : '変更申請';
        }

        // --- submitted ---
        if (_existingPersonalStatus == ReportStatus.submitted) {
          if (_changedFromBaseline) {
            // 権限者は「変更」、一般ユーザーは「変更申請」
            return isPrivileged ? '更新' : '変更申請';
          }
          return null;
        }
      }

      // --- 新規作成 ---
      return '提出';
    }
  }
  final actionLabel = _actionLabel();

  // ===== 削除権限判定（サーバの permissions に完全準拠）=====
  final bool isDetail = viewingExistingPersonal || viewingExistingTeam;
  final bool canDelete = (widget.initialTeam?.permissions.canDelete ?? false) || (widget.initialPersonal?.permissions.canDelete ?? false);

    return Scaffold(
      backgroundColor: isPersonalPending ? Colors.amber[50] : null,
      appBar: AppBar(
        title : Text(isDetail ? '日報の詳細' : '日報の作成'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color : Theme.of(context).colorScheme.outline,
          ),
        ),

        actions: [
          if (actionLabel != null)
            TextButton(
              onPressed: _saving ? null : _onSubmit,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(actionLabel, style: Theme.of(context).textTheme.bodyLarge),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              if (isPersonalPending)
                Center(
                  child: Text(
                    '変更申請中',
                    style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              

              // ---- 基本情報カード ----
              _InfoCard(
                color: isPersonalPending ? Colors.amber[50] : null,
                children: [
                  LabelWithButtonRow(
                    label: '日付',
                    value: _formatDate(_date),
                    onTap: (viewingExistingPersonal || viewingExistingTeam) ? null : _pickDate,
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(labelText: 'レポートメモ（任意）'),
                    maxLines: 2,
                  ),
                ]
              ),

              const SizedBox(height: 16),

              // ---- 明細カード ----
              _InfoCard(
                color: isPersonalPending ? Colors.amber[50] : null,
                children: [
                  Row(
                    children: [
                      Text('作業明細', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: (_existingPersonalStatus == ReportStatus.locked)
                            ? null
                            : () => setState(() => _rows.add(_EntryRow())),
                        icon: const Icon(Icons.add),
                        // チーム時は「現場を追加」、個人時は「行を追加」
                        label: Text('現場を追加'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._rows.asMap().entries.map((e) {
                    final idx = e.key;
                    final row = e.value;
                    return _EntryEditor(
                      key: ValueKey('row_$idx'),
                      row: row,
                      onDelete: _rows.length == 1
                          ? null
                          : () {
                              setState(() => _rows.removeAt(idx));
                            },
                      onPickSite: () => _pickSite(row),
                      onPickWorkCategory: () => _pickWorkCategory(row),
                      onPickMember: () => _pickMember(row),
                      onPickStart: () => _pickTime(row, isStart: true),
                      onPickEnd: () => _pickTime(row, isStart: false),
                      showMember: showMember,
                      onRowChanged: () => setState(() {}),
                    );
                  }),
                ]
              ),

              const SizedBox(height: 24),

              if (actionLabel != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _onSubmit,
                  icon: const Icon(Icons.send),
                  label: Text(actionLabel),
                ),

              if (canDelete) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : () => _onDelete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('削除'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========== Actions ==========
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023, 1, 1),
      lastDate : DateTime(2030, 12, 31),
    );
    if (picked == null) return;

    setState(() => _date = DateUtils.dateOnly(picked));

    if (_target == ReportTarget.personal) {
      await _prefillFromPersonal(_date);
    } else if (_target == ReportTarget.team && _teamId != null) {
      await _prefillTeamForDate(teamId: _teamId!, date: _date);
    }
  }

  Future<void> _pickAdminTeam() async {
    final selected = await showModalBottomSheet<TeamInfo?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const TeamPickerSheet(showPersonalOption: true),
    );

    if (!mounted) return;

    if (selected == null) {
      setState(() {
        _target   = ReportTarget.personal;
        _teamId   = null;
        _teamName = null;

        // ★ ここを複数対応に
        for (final r in _rows) {
          r.members.clear();
        }
      });
      await _prefillFromPersonal(_date);
    } else {
      setState(() {
        _target   = ReportTarget.team;
        _teamId   = selected.id;
        _teamName = selected.name;
        _existingPersonalId = null;
        _existingPersonalStatus = null;
        _baselineSig        = null;
      });

      await _prefillTeamForDate(teamId: _teamId!, date: _date);
    }
  }

  List<String> _leaderTeamIdsOfCurrentUser() {
    final u = ref.read(userProvider);
    if (u == null) return const [];
    return u.teams
        .where((t) => t.role == 'leader')
        .map((t) => t.id)
        .toList(growable: false);
  }

  Future<void> _pickTeam() async {
    // リーダーが選べるチーム（自分がleaderのチーム）だけ
    final allowed = _leaderTeamIdsOfCurrentUser();

    final selected = await showModalBottomSheet<TeamInfo?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TeamPickerSheet(
        showPersonalOption: true,
        allowedTeamIds: allowed, // ← ここが肝
      ),
    );

    if (!mounted) return;

    if (selected == null) {
      setState(() {
        _target   = ReportTarget.personal;
        _teamId   = null;
        _teamName = null;
        for (final r in _rows) {
          r.members.clear();
        }
      });
      await _prefillFromPersonal(_date);
    } else {
      // 念のため、防御的チェック（UI側で絞っているが二重で守る）
      if (!allowed.contains(selected.id)) {
        _snack('このチームは選択できません');
        return;
      }

      setState(() {
        _target   = ReportTarget.team;
        _teamId   = selected.id;
        _teamName = selected.name;
        _existingPersonalId = null;
        _existingPersonalStatus = null;
        _baselineSig        = null;
      });

      await _prefillTeamForDate(teamId: _teamId!, date: _date);
    }
  }

  Future<void> _pickSite(_EntryRow row) async {
    await showSiteSelectorModal(
      context: context,
      onSelected: (site) {
        setState(() => row.site = site);
      },
    );
  }

  Future<void> _pickWorkCategory(_EntryRow row) async {
    await showWorkSelectorModal(
      context: context,
      showClearOption: true,
      onCleared: () => setState(() => row.workCategory = null),
      onSelected: (work) => setState(() => row.workCategory = work),
    );
  }

 
  // 1) MemberModel -> SimpleUserModel 変換（id を堅牢に数値化）
  SimpleUserModel _toSimple(MemberModel m) {
    int idInt;
    try {
      idInt = int.parse(m.id);        // m.id が String の想定
    } catch (_) {
      idInt = 0;                      // フォールバック
    }
    return SimpleUserModel(
      id: idInt,
      email: '',
      username: m.name,
      accountId: '',
      iconimg: m.avatarUrl,
      role: UserRole.member,
      teams: const [],
    );
  }

  // 2) どんな戻り値でも List<SimpleUserModel> に正規化
  List<SimpleUserModel> _asSimpleList(dynamic v) {
    if (v is List<SimpleUserModel>) return v;
    if (v is List<MemberModel>) return v.map(_toSimple).toList(growable: false);
    if (v is List) {
      final out = <SimpleUserModel>[];
      for (final e in v) {
        if (e is SimpleUserModel) {
          out.add(e);
        } else if (e is MemberModel) {
          out.add(_toSimple(e));
        } else if (e is Map<String, dynamic>) {
          try {
            out.add(SimpleUserModel.fromJson(e));
          } catch (_) {/* 無視 */}
        }
      }
      return out;
    }
    return const <SimpleUserModel>[];
  }

  // 3) _pickMember を差し替え
  Future<void> _pickMember(_EntryRow row) async {
    final result = await showMultiMemberSelectorModal(
      context: context,
      // ※ ここは先に直した通り String 配列で渡す
      initialSelectedIds: row.memberIds.map((e) => e.toString()).toList(growable: false),
      resolveUrl: resolveImageUrl,
    );
    if (!mounted || result == null) return;

    setState(() {
      row.members = _asSimpleList(result); // 常に SimpleUserModel に統一
    });
  }

  Future<void> _pickTime(_EntryRow row, {required bool isStart}) async {
    final current = isStart ? row.start : row.end; // 非null

    final initial = DateTime(
      _date.year, _date.month, _date.day, current.hour, current.minute,
    );

    showTimePickerModal(
      context: context,
      initialDateTime: initial,
      onTimePicked: (dt) {
        setState(() {
          final picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
          if (isStart) {
            row.start = picked;
          } else {
            row.end = picked;
          }
        });
      },
    );
  }

  // 下書き保存処理はMVPでは実装しない
  // Future<void> _onSaveDraft() async {
  //   if (!_validateForm(showSnackBar: true)) return;
  //   setState(() => _saving = true);
  //   try {
  //     // ここで後ほど API に接続（status=draft）
  //     _comingSoon('下書き保存（API接続は後で実装）');
  //   } finally {
  //     if (mounted) setState(() => _saving = false);
  //   }
  // }

  Future<void> _onSubmit() async {
    if (!_validateForm(showSnackBar: true)) return;

    setState(() => _saving = true);
    try {
      if (_target == ReportTarget.team) {

        if (_teamId == null || _teamId!.isEmpty) {
          _snack('チームを選択してください');
          return;
        }

        // 既存 submitted があるなら更新、無ければ新規
        final isUpdate = _existingTeamId != null;

        if (isUpdate && !_changedFromBaseline) {
          _snack('変更点がありません');
          return;
        }

        // 行データから TeamReportEntryModel を生成（行×メンバーでフラット化）
        final entries = _buildEntriesFromRows();

        if (!isUpdate) {
          final teamSummary = TeamSummaryModel.fromJson({'id': _teamId!, 'name': _teamName ?? ''});
          final createdByStub = SimpleUserModel(
            id: 0,
            email: '',
            username: '',
            accountId: '',
            iconimg: null,
            role: UserRole.member,
            teams: const [],
          );

          final model = TeamReportModel(
            id: '',
            date: _date,
            status: ReportStatus.submitted,
            team: teamSummary,
            note: _noteCtrl.text.trim(),
            createdBy: createdByStub,
            createdAt: DateTime.now(),
            submittedAt: DateTime.now(),
            entries: entries,
          );

          final query = TeamReportListQuery(start: _date, end: _date, teamId: _teamId);
          final created = await ref.read(teamReportListProvider(query).notifier)
              .create(model: model, teamId: _teamId!);

          await ref.read(teamReportListProvider(query).notifier)
              .generatePersonalDraft(teamReportId: created.id, replaceExisting: true);

          _snack('チーム日報を作成しました');
          if (mounted) Navigator.of(context).pop(created);
        } else {
          // --- 更新 ---
          final patch = {
            'status' : 'submitted',
            'note'   : _noteCtrl.text.trim(),
            'entries': entries.map((e) => {
              'site_id'         : e.site.id,
              'member_id'       : e.member.id,
              'work_category_id': e.workCategory?.id,
              'start_time'      : '${e.startTime.hour.toString().padLeft(2, '0')}:${e.startTime.minute.toString().padLeft(2, '0')}',
              'end_time'        : '${e.endTime.hour.toString().padLeft(2, '0')}:${e.endTime.minute.toString().padLeft(2, '0')}',
              'note'            : e.note?.trim() ?? '',
            }).toList(),
          };
          final query = TeamReportListQuery(start: _date, end: _date, teamId: _teamId);
          final updated = await ref.read(teamReportListProvider(query).notifier)
              .update(id: _existingTeamId!, patch: patch);

          await ref.read(teamReportListProvider(query).notifier)
              .generatePersonalDraft(teamReportId: updated.id, replaceExisting: true);

          _snack('チーム日報を更新しました');
          if (mounted) Navigator.of(context).pop(updated);
        }
        return; // 以降の個人分岐へ落ちないように
      } else {
        // ==== 個人日報の作成 ====
        if (_existingPersonalId != null) {
          // 既存がある → 更新（サーバ側で差分があれば pending にされる）
          final patch = <String, dynamic>{
            'status' : 'submitted',  // いつも submitted を送る。差分ありはサーバが pending へ
            'note'   : _noteCtrl.text.trim(),
            'entries': _buildPersonalEntryPayloads(), // 全入れ替え
          };
          final q = PersonalReportListQuery(
            start: _date,                // ← 一覧画面が watch しているのと同じ条件に合わせる
            end: _date,
            userIdParam: 'me',
          );
          final updated = await ref
            .read(personalReportListProvider(q).notifier)
            .update(id: _existingPersonalId!, patch: patch);

          final bool isPrivileged = _isPrivilegedUser;
          final bool canApprovePersonal = _canApproveCurrentPersonal;

          // 表示用メッセージを状況に合わせて最適化
          String msg;
          if (_existingPersonalStatus == ReportStatus.pending) {
            if (canApprovePersonal && !_changedFromBaseline) {
              msg = '承認しました';
            } else {
              msg = '変更申請を送信しました';
            }
          } else if (_existingPersonalStatus == ReportStatus.draft) {
            if (!_changedFromBaseline) {
              msg = '個人日報を提出しました';
            } else {
              msg = isPrivileged ? '個人日報を提出しました' : '変更申請を送信しました';
            }
          } else {
            // submitted からの変更
            if (_changedFromBaseline) {
              msg = isPrivileged ? '日報を更新しました' : '変更申請を送信しました';
            } else {
              msg = '個人日報を提出しました';
            }
          }

          _snack(msg);
          if (mounted) Navigator.of(context).pop(updated);
        } else {
          // 既存が無い → 新規作成（従来ロジック）
          final entries = _buildPersonalEntriesFromRows();
          final stubUser = SimpleUserModel(id: 0, email: '', username: '', accountId: '', iconimg: null, role: UserRole.member, teams: const [],);
          final model = PersonalReportModel(
            id: '',
            date: _date,
            status: ReportStatus.submitted,
            user: stubUser,
            entries: entries,
            createdAt: DateTime.now(),
            note: _noteCtrl.text.trim(),
            submittedAt: DateTime.now(),
          );

          // 一旦 “当日 & me” の Family を叩いて作成
          final q = PersonalReportListQuery(start: _date, end: _date, userIdParam: 'me');
          final created = await ref
              .read(personalReportListProvider(q).notifier)
              .create(model: model);

          _snack('個人日報を作成しました');
          if (mounted) Navigator.of(context).pop(created);
        }
      }
    } catch (e) {
      _snack('作成に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context: context,
      title: '削除の確認',
      message: 'この日報を削除します。よろしいですか？',
      okLabel: '削除する',
      cancelLabel: 'キャンセル',
    );
    if (!ok) return;

    setState(() => _saving = true);
    try {
      if (widget.initialTeam != null) {
        // チーム日報削除（List Provider の remove を呼ぶだけ）
        await ref
            .read(teamReportListProvider(const TeamReportListQuery()).notifier)
            .remove(widget.initialTeam!.id);
      } else if (widget.initialPersonal != null) {
        // 個人日報削除（List Provider の remove を呼ぶだけ）
        await ref
            .read(personalReportListProvider(const PersonalReportListQuery()).notifier)
            .remove(widget.initialPersonal!.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // 一覧へ戻る
    } catch (e) {
      _snack('削除に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // チーム日報のエントリ変換
  List<TeamReportEntryModel> _buildEntriesFromRows() {
    final out = <TeamReportEntryModel>[];
    for (final r in _rows) {
      final site = r.site!; // validate 済み前提
      for (final m in r.members) {
        out.add(
          TeamReportEntryModel(
            id        : '', // サーバー側採番想定なので空でOK
            site      : site,
            member    : m,
            startTime : r.start,
            endTime   : r.end,
            workCategory: r.workCategory,
            note      : (r.note ?? '').trim(),
          ),
        );
      }
    }
    return out;
  }

  // 個人日報のエントリ変換
  List<PersonalReportEntryModel> _buildPersonalEntriesFromRows() {
    final out = <PersonalReportEntryModel>[];
    for (final r in _rows) {
      final site = r.site!; // validate 済み前提
      out.add(
        PersonalReportEntryModel(
          id        : '', // サーバ採番想定
          site      : site,
          startTime : r.start,
          endTime   : r.end,
          workCategory: r.workCategory,
          note      : r.note,
        ),
      );
    }
    return out;
  }

  Future<void> _prefillFromPersonal(DateTime date) async {
    if (_target != ReportTarget.personal) return;
    try {
      final dio = ref.read(dioProvider);
      final pr = await fetchMyPersonalReportForDay(dio, start: date);
      if (!mounted) return;

      setState(() {
        if (pr == null) {
          // 既存なし → 新規扱い（ベースラインは無効 = 変更申請表示なし）
          _existingPersonalId = null;
          _existingPersonalStatus = null;
          _noteCtrl.text = '';
          _rows
            ..clear()
            ..add(_EntryRow());
          _baselineSig = null;
          return;
        }

        // 既存あり → 画面に反映
        _existingPersonalId = pr.id;
        _existingPersonalStatus = pr.status;
        _noteCtrl.text = pr.note ?? '';
        _rows.clear();
        for (final e in pr.entries) {
          final row = _EntryRow()
            ..site         = e.site
            ..workCategory = e.workCategory
            ..start        = e.startTime
            ..end          = e.endTime
            ..note         = e.note;
          _rows.add(row);
        }
        if (_rows.isEmpty) _rows.add(_EntryRow());

        if (pr.status != ReportStatus.locked) {  // ★変更
          _captureBaseline();
        } else {
          _baselineSig = null;
        }
      });
    } catch (_) {
      _snack('テンプレ取得に失敗しました');
    }
  }

  Future<void> _prefillFromTeam(DateTime date, String teamId) async {
    try {
      final dio = ref.read(dioProvider);

      // 当日の 00:00～23:59 でスケジュール検索
      final dayStart = DateTime(date.year, date.month, date.day);
      // サーバが「< end」でも「<= end」でも必ず当日が入るように、23:59:59.999 として送る
      final dayEnd   = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final schedules = await fetchTeamMonthlySchedules(
        dio: dio,
        teamId: teamId,          // ← null を許す API にしたので必ず渡す
        start: dayStart,
        end: dayEnd,
      );

      if (!mounted) return;

      // ---- ひな形生成 ----
      setState(() {
        _existingPersonalId = null;
        _existingTeamId = null;
        _baselineSig        = null;

        _rows.clear();

        if (schedules.isEmpty) {
          // 予定が無ければ空行 1 行
          _rows.add(_EntryRow());
          return;
        }

        for (final sch in schedules) {
          // ScheduleModel → _EntryRow へ変換
          _rows.add(
            _EntryRow(
              members: _asSimpleList(sch.members),
              start  : TimeOfDay.fromDateTime(sch.startTime.toLocal()),
              end    : TimeOfDay.fromDateTime(sch.endTime.toLocal()),
            )
              ..site          = sch.site
              ..workCategory  = sch.workCategory
          );
        }
      });
    } catch (_) {
      _snack('スケジュール取得に失敗しました');
    }
  }


  Future<void> _prefillTeamForDate({required String teamId, required DateTime date}) async {
    try {
      final dio = ref.read(dioProvider);
      final list = await fetchTeamReports(
        dio,
        start: DateTime(date.year, date.month, date.day),
        end  : DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
        teamId: teamId,
        memberId: null,
      );

      // submitted があれば編集モードへ
      final existing = list.where((r) => r.status == ReportStatus.submitted).toList();
      if (existing.isNotEmpty) {
        _prefillFromGivenTeam(existing.first);
        return;
      }
    } catch (_) {
      // 無視してスケジュール初期化へフォールバック
    }

    // 既存なし → スケジュールから初期値（新規作成モード）
    await _prefillFromTeam(date, teamId);
    if (mounted) {
      setState(() {
        _existingTeamId = null;  // 新規モード
        _baselineSig    = null;  // 差分判定なし
      });
    }
  }

  bool _validateForm({bool showSnackBar = false}) {
    final user = ref.read(userProvider);
    final bool isAdmin = user?.isAdmin ?? false;
    final bool isManager = user?.isManager ?? false;
    final bool isTeamLeader = (user?.teams ?? const []).any((t) => t.role == 'leader');
    final bool canSelectTeam = isAdmin || isManager || isTeamLeader;

    final ReportTarget effective = canSelectTeam ? _target : ReportTarget.personal;

    if (effective == ReportTarget.team && _teamId == null) {
      if (showSnackBar) _snack('チームを選択してください');
      return false;
    }
    if (_rows.isEmpty) {
      if (showSnackBar) _snack('作業明細を1件以上追加してください');
      return false;
    }

    int _m(TimeOfDay t) => t.hour * 60 + t.minute;

    // 基本チェック（現場選択・時刻順序）
    for (final r in _rows) {
      if (r.site?.id == null) {
        if (showSnackBar) _snack('現場が未選択の行があります');
        return false;
      }
      if (effective == ReportTarget.team && r.members.isEmpty) {
        if (showSnackBar) _snack('メンバーが未選択の行があります');
        return false;
      }
      final s = _m(r.start), e = _m(r.end);
      if (s >= e) { // 等値と逆転の両方を禁止
        if (showSnackBar) _snack('開始は終了より前である必要があります');
        return false;
      }
    }

    // --- 追加：重複判定 ---
    if (effective == ReportTarget.personal) {
      // 個人：行同士の重複を検出（端が接するのはOK）
      final items = _rows.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        return (idx: i, s: _m(r.start), e: _m(r.end));
      }).toList()
        ..sort((a, b) => a.s.compareTo(b.s));

      for (var i = 1; i < items.length; i++) {
        final prev = items[i - 1];
        final cur  = items[i];
        if (cur.s < prev.e) {
          if (showSnackBar) {
            _snack('時間が重複しています');
          }
          return false;
        }
      }
    } else {
      // チーム：同一メンバーごとの重複を検出
      final Map<int, List<(int s, int e, int rowIdx, String name)>> bag = {};
      for (final entry in _rows.asMap().entries) {
        final i = entry.key;
        final r = entry.value;
        for (final m in r.members) {
          bag.putIfAbsent(m.id, () => <(int,int,int,String)>[])
            .add((_m(r.start), _m(r.end), i, m.username));
        }
      }
      for (final list in bag.values) {
        list.sort((a, b) => a.$1.compareTo(b.$1));
        for (var i = 1; i < list.length; i++) {
          final prev = list[i - 1];
          final cur  = list[i];
          if (cur.$1 < prev.$2) {
            if (showSnackBar) {
              _snack('メンバー ${cur.$4} の時間が重複しています');
            }
            return false;
          }
        }
      }
    }
    return true;
  }


  // ========== helpers ==========
  String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

  // void _comingSoon(String msg) {
  //   ScaffoldMessenger.of(context)
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(SnackBar(content: Text(msg)));
  // }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _EntryEditor extends StatelessWidget {
  final _EntryRow row;
  final VoidCallback? onDelete;

  final VoidCallback onPickSite;
  final VoidCallback onPickWorkCategory;
  final VoidCallback onPickMember;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  final bool showMember;

  final VoidCallback? onRowChanged;

  const _EntryEditor({
    super.key,
    required this.row,
    required this.onDelete,
    required this.onPickSite,
    required this.onPickWorkCategory,
    required this.onPickMember,
    required this.onPickStart,
    required this.onPickEnd,
    required this.showMember,
    this.onRowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final membersKey = row.members.map((m) => m.id).join('_');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 現場／作業（縦並び・フル幅） ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'この行を削除',
                  ),
                ),
              ],
              LabelWithButtonRow(
                key: ValueKey('site_${row.site?.id ?? "none"}'),
                label: '現場',
                value: row.site?.name ?? '未選択',
                onTap: onPickSite,
              ),
              const SizedBox(height: 8),
              LabelWithButtonRow(
                key: ValueKey('work_${row.workCategory?.id ?? "none"}'),
                label: '作業',
                value: row.workCategory?.name ?? '（任意）',
                onTap: onPickWorkCategory,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- メンバー（チームのときだけ表示） ---
          if (showMember) ...[
            LabelWithButtonRow(
              key: ValueKey('members_$membersKey'),
              label: 'メンバー',
              value: row.members.isEmpty ? '未選択' : '${row.members.length}名',
              onTap: onPickMember,
            ),
            if (row.members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: row.members.map((m) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildAvatar(
                        context: context,
                        imageUrl: m.iconimg,
                        radius: 20,
                        resolveUrl: resolveImageUrl,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 56,
                        child: Text(
                          m.username,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
          ],

          // --- 開始／終了（縦並び） ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabelWithButtonRow(
                key: ValueKey('start_${row.start.format(context)}'),
                label: '開始',
                value: _fmt(row.start),
                onTap: onPickStart,
              ),
              const SizedBox(height: 8),
              LabelWithButtonRow(
                key: ValueKey('end_${row.end.format(context)}'),
                label: '終了',
                value: _fmt(row.end),
                onTap: onPickEnd,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- 行メモ ---
          TextFormField(
            initialValue: row.note,
            onChanged: (v) {
              row.note = v;
              onRowChanged?.call();
            },
            decoration: const InputDecoration(labelText: '行メモ（任意）'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}


/// 画面内でのみ使うシンプルカード
class _InfoCard extends StatelessWidget {
  final Color? color;
  final List<Widget> children;
  const _InfoCard({required this.children, this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: children),
      );
}

/// スケジュール画面で使っている行UIを簡略化して同梱
class LabelWithButtonRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const LabelWithButtonRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ローカル行モデル（最小）
class _EntryRow {
  SiteModel?          site;
  WorkCategoryModel?  workCategory;
  List<SimpleUserModel> members;

  TimeOfDay start;
  TimeOfDay end;
  String? note;

  _EntryRow({
    List<SimpleUserModel>? members,
    TimeOfDay? start,
    TimeOfDay? end,
  })  : members = members ?? <SimpleUserModel>[],
        start   = start ?? const TimeOfDay(hour: 8,  minute: 0),
        end     = end   ?? const TimeOfDay(hour: 17, minute: 0);

  List<int> get memberIds => members.map((u) => u.id).toList(growable: false);
}

