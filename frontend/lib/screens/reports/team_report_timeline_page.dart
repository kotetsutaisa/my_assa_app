// /lib/screens/reports/team_report_timeline_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/reports/team_report_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/providers/reports/team_report_provider.dart'; // teamReportListProvider, TeamReportListQuery
import 'package:frontend/screens/profile/profile_tab_page.dart';
import 'package:frontend/widgets/reports/range_header.dart';
import 'package:frontend/widgets/reports/shimmer_list.dart';
import 'package:frontend/widgets/reports/team_report_card.dart';
// 作成/詳細ページ
import 'package:frontend/screens/reports/report_create_page.dart';
// ← ここは「クラス」ではなく関数を提供するファイル
import 'package:frontend/widgets/dialogs/confirm_dialog.dart'; // showConfirmDialog を export している

/// 7日単位のタイムライン（中身だけ）
class TeamReportTimelineView extends ConsumerStatefulWidget {
  /// 特定チームだけに絞る場合
  final String? teamId;
  const TeamReportTimelineView({super.key, this.teamId});

  @override
  ConsumerState<TeamReportTimelineView> createState() => _TeamReportTimelineViewState();
}

class _TeamReportTimelineViewState extends ConsumerState<TeamReportTimelineView> {
  /// 表示対象の開始日（7日ウィンドウの先頭）。初期は「今週日曜」〜「土曜」。
  late DateTime _rangeStart;

  /// 行（サイト×作業）ごとの展開状態管理
  final Set<String> _expandedRowKeys = <String>{};

  /// 与えた日付が含まれる週の「日曜日」を返す（週の始まりを日曜に固定）
  DateTime _startOfWeekSunday(DateTime d) {
    final dd = DateUtils.dateOnly(d);
    final delta = dd.weekday % 7; // Mon=1..Sun=7 → Sunだけ0、他は1..6
    return dd.subtract(Duration(days: delta));
  }

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _rangeStart = _startOfWeekSunday(today);
  }

  DateTime get _rangeEnd => _rangeStart.add(const Duration(days: 6)); // 常に土曜

  void _goPrevRange() => setState(() => _rangeStart = _rangeStart.subtract(const Duration(days: 7)));
  void _goNextRange() => setState(() => _rangeStart = _rangeStart.add(const Duration(days: 7)));

  Future<void> _refresh() async {
    final q = TeamReportListQuery(start: _rangeStart, end: _rangeEnd, teamId: widget.teamId);
    await ref.read(teamReportListProvider(q).notifier).refresh();
  }

  String _formatRangeLabel(DateTime start, DateTime end) {
    // 例: 7/27(日) – 8/2(土)
    const wdJP = ['月', '火', '水', '木', '金', '土', '日'];
    String f(DateTime d) {
      final m = d.month;
      final day = d.day;
      final wd = wdJP[d.weekday - 1]; // DateTime.weekday: Mon=1..Sun=7
      return '$m/$day($wd)';
    }
    return '${f(start)} – ${f(end)}';
  }

  String _formatDateHeader(DateTime d) {
    // 例: 7月29日(火)
    const wdJP = ['月', '火', '水', '木', '金', '土', '日'];
    final m = d.month;
    final day = d.day;
    final wd = wdJP[d.weekday - 1];
    return '$m月$day日($wd)';
  }

  void _handleOpenDetail(TeamReportModel report) {
    if (!(report.permissions.canViewDetail)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('権限がありません')));
      return;
    }
    _openTeamReportDetail(report, context);
  }

  @override
  Widget build(BuildContext context) {
    final q = TeamReportListQuery(start: _rangeStart, end: _rangeEnd, teamId: widget.teamId);
    final asyncReports = ref.watch(teamReportListProvider(q));

    return Column(
      children: [
        // 期間ヘッダー（タブやScaffoldは親で管理）
        RangeHeader(
          label: _formatRangeLabel(_rangeStart, _rangeEnd),
          onPrev: _goPrevRange,
          onNext: _goNextRange,
        ),
        // 親の ReportsRootPage が Divider を持つため、ここでは追加しない

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: asyncReports.when(
              loading: () => const ShimmerList(),
              error: (e, st) => ListView(
                children: [
                  const SizedBox(height: 48),
                  Center(child: Text('読み込みに失敗しました: $e')),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再読み込み'),
                    ),
                  ),
                ],
              ),
              data: (list) {
                // 未提出は表示しない
                final submitted = list.where((r) => r.status == ReportStatus.submitted).toList();

                // 週範囲内を日付別にグループ → 空の日付は一切表示しない
                final byDate = <DateTime, List<TeamReportModel>>{};
                for (final r in submitted) {
                  final d = DateUtils.dateOnly(r.date);
                  byDate.putIfAbsent(d, () => []).add(r);
                }
                if (byDate.isEmpty) {
                  // 空 → 何も表示しない（ただし Pull to refresh のために ListView は返す）
                return ListView();
                }

                final dates = byDate.keys.toList()..sort();
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: dates.length,
                  itemBuilder: (_, i) {
                    final d = dates[i];
                    final reportsOfDay = byDate[d]!;
                    // 日付セクション
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _formatDateHeader(d),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...reportsOfDay.map((tr) => TeamReportCard(
                              report: tr,
                              expandedRowKeys: _expandedRowKeys,
                              onToggleExpand: (key, expanded) {
                                setState(() {
                                  if (expanded) {
                                    _expandedRowKeys.add(key);
                                  } else {
                                    _expandedRowKeys.remove(key);
                                  }
                                });
                              },
                              // タップ時の詳細表示（権限チェック込み）
                              onTapTeam  : () => _handleOpenDetail(tr),
                              onTapDetail: () => _handleOpenDetail(tr),
                              onTapMember: (userId) => _openProfile(userId, context),

                              showDelete: tr.permissions.canDelete,
                              onTapDelete: tr.permissions.canDelete
                                  ? () async {
                                      final ok = await showConfirmDialog(
                                        context: context,
                                        title: '削除確認',
                                        message: 'このチーム日報を削除します。よろしいですか？',
                                        okLabel: '削除',
                                        cancelLabel: 'キャンセル',
                                      );
                                      if (!ok) return;
                                      final q = TeamReportListQuery(start: _rangeStart, end: _rangeEnd, teamId: widget.teamId);
                                      await ref.read(teamReportListProvider(q).notifier).remove(tr.id);
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(const SnackBar(content: Text('削除しました')));
                                    }
                                  : null,
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ========== Navigation ==========
  void _openTeamReportDetail(TeamReportModel report, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsCreatePage(initialTeam: report),
      ),
    );
  }

  void _openProfile(int userId, BuildContext context) {
    ref.read(currentPageProvider.notifier).state = ProfileTabPage(userId: userId);
  }
}



