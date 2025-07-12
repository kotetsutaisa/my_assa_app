/// lib/screens/schedule/edit_team_schedule_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/models/member_model.dart';
import 'package:frontend/providers/team_member_provider.dart';
import 'package:frontend/providers/team_schedule_provider.dart';
import 'package:frontend/providers/work_category_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/schedule_widget/date_dropdown_picker.dart';
import 'package:frontend/widgets/schedule_widget/label_with_button_row.dart';
import 'package:frontend/widgets/schedule_widget/label_with_widget_row.dart';
import 'package:frontend/widgets/schedule_widget/site_selector_modal.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';
import 'package:frontend/widgets/schedule_widget/work_selector_model.dart';
import 'package:intl/intl.dart';

class EditTeamSchedulePage extends ConsumerStatefulWidget {
  final ScheduleModel schedule;
  const EditTeamSchedulePage({super.key, required this.schedule});

  @override
  ConsumerState<EditTeamSchedulePage> createState() => _EditTeamSchedulePage();
}

class _EditTeamSchedulePage extends ConsumerState<EditTeamSchedulePage> {
  /* ── 選択中データ ── */
  late SiteModel?         _selectedSite;
  late WorkCategoryModel? _selectedWorkCategory;
  late final _selectedMembers = <MemberModel>[];

  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final sch = widget.schedule;
    _selectedSite         = sch.site;
    _selectedWorkCategory = sch.workCategory;
    _selectedStartDate    = sch.startTime;
    _selectedEndDate      = sch.endTime;
    _startTime            = sch.startTime;
    _endTime              = sch.endTime;
    /* 既存メンバーを初期セット（SimpleUserModel → MemberModel 変換は適宜） */
    _selectedMembers.addAll(sch.members.map((u) =>
        MemberModel(id: u.id.toString(), name: u.username, avatarUrl: u.iconimg)));
  }

  /* ── 共通 util ── */
  void _showError(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  /* ── メンバー選択モーダル ── */
  Future<void> _showMemberSelector() async {
    final allMembers = await ref.read(teamMemberListProvider.future);

    final result = await showModalBottomSheet<List<MemberModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final temp = [..._selectedMembers];
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('メンバーを選択', style: Theme.of(ctx).textTheme.titleMedium),
                const Divider(),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    itemCount: allMembers.length,
                    itemBuilder: (_, i) {
                      final m = allMembers[i];
                      final checked = temp.any((e) => e.id == m.id);
                      return CheckboxListTile(
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundImage: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(_resolveImageUrl(m.avatarUrl!))
                              : null,
                          child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
                              ? Text(m.name.characters.first,
                                  style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        title: Text(m.name),
                        value: checked,
                        onChanged: (v) => setModal(() {
                          v == true
                              ? temp.add(m)
                              : temp.removeWhere((e) => e.id == m.id);
                        }),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル'))),
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('決定'))),
                  ],
                )
              ],
            ),
          );
        });
      },
    );

    if (result != null) setState(() {
      _selectedMembers
        ..clear()
        ..addAll(result);
    });
  }

  /* ── build ── */
  @override
  Widget build(BuildContext context) {
    final memberLabel = _selectedMembers.isEmpty
        ? 'メンバーを選択'
        : '${_selectedMembers.length}名';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title : Text('編集', style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
        ),
        actions: [
          TextButton(
            child: Text('変更', style: Theme.of(context).textTheme.bodyLarge),
            onPressed: _save,
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /* ── 上段カード ── */
              _InfoCard(children: [
                LabelWithButtonRow(
                  label: '現場',
                  value: _selectedSite?.name ?? widget.schedule.siteName,
                  onTap : () => showSiteSelectorModal(
                    context: context,
                    onSelected: (s) => setState(() => _selectedSite = s),
                  ),
                ),
                const Divider(),
                LabelWithButtonRow(
                  label: '作業内容',
                  value: _selectedWorkCategory?.name ?? widget.schedule.workCategory?.name ?? '',
                  onTap : () async {
                    await showWorkSelectorModal(
                      context: context,
                      onSelected: (w) => setState(() => _selectedWorkCategory = w),
                    );
                    final list = ref.read(workCategoryListProvider).value ?? [];
                    if (!list.any((w) => w.id == _selectedWorkCategory?.id)) {
                      setState(() => _selectedWorkCategory = null);
                    }
                  },
                ),
                const Divider(),
                LabelWithButtonRow(
                  label: 'メンバー',
                  value: memberLabel,
                  onTap : _showMemberSelector,
                ),
                if (_selectedMembers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: _selectedMembers.map((m) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(_resolveImageUrl(m.avatarUrl!))
                              : null,
                          child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
                              ? Text(m.name.characters.first,
                                  style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 48,
                          child: Text(
                            m.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ],
              ]),

              const SizedBox(height: 32),

              /* ── 下段カード ── */
              _InfoCard(children: [
                LabelWithWidgetRow(
                  label: '開始日',
                  time : Text(DateFormat.Hm().format(_startTime),
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTimeTap: () => showTimePickerModal(
                    context: context,
                    initialDateTime: _startTime,
                    onTimePicked: (t) => setState(() => _startTime = t),
                  ),
                  child: DateDropdownPicker(
                    selectedDate  : _selectedStartDate,
                    onDateSelected: (d) => setState(() => _selectedStartDate = d),
                  ),
                ),
                const Divider(),
                LabelWithWidgetRow(
                  label: '終了日',
                  time : Text(DateFormat.Hm().format(_endTime),
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTimeTap: () => showTimePickerModal(
                    context: context,
                    initialDateTime: _endTime,
                    onTimePicked: (t) => setState(() => _endTime = t),
                  ),
                  child: DateDropdownPicker(
                    selectedDate  : _selectedEndDate,
                    onDateSelected: (d) => setState(() => _selectedEndDate = d),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /* ── 保存処理 ── */
  Future<void> _save() async {
    if (_selectedSite == null)          return _showError('現場は必須です');
    if (_selectedWorkCategory == null)  return _showError('作業内容は必須です');
    if (_selectedMembers.isEmpty)       return _showError('メンバーを選択してください');

    final start = DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day,
                           _startTime.hour, _startTime.minute);
    final end   = DateTime(_selectedEndDate.year,   _selectedEndDate.month,   _selectedEndDate.day,
                           _endTime.hour,   _endTime.minute);
    if (!end.isAfter(start)) return _showError('終了日時は開始日時より後にしてください');

    try {
      await ref.read(teamScheduleMapProvider.notifier).updateSchedule(
        id                  : widget.schedule.id,
        selectedSite        : _selectedSite!,
        selectedWorkCategory: _selectedWorkCategory!,
        memberIds           : _selectedMembers.map((e) => e.id).toList(), // ★ 追加
        selectedStartDate   : _selectedStartDate,
        startTime           : _startTime,
        selectedEndDate     : _selectedEndDate,
        endTime             : _endTime,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('更新に失敗しました: $e');
    }
  }
}

/* ── 共通カード ── */
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      );
}
