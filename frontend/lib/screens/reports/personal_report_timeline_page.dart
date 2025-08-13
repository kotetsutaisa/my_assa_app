import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/reports/personal_report_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/providers/reports/personal_report_provider.dart';
import 'package:frontend/screens/profile/profile_tab_page.dart';
import 'package:frontend/screens/reports/report_create_page.dart';
import 'package:frontend/widgets/reports/shimmer_list.dart';
import 'package:frontend/widgets/reports/day_header.dart';
import 'package:frontend/widgets/reports/personal_report_card.dart';
import 'package:frontend/widgets/dialogs/confirm_dialog.dart'; // ← 追加（共通ダイアログ）

class PersonalReportTimelineView extends ConsumerStatefulWidget {
  const PersonalReportTimelineView({super.key});

  @override
  ConsumerState<PersonalReportTimelineView> createState() =>
      _PersonalReportTimelineViewState();
}

class _PersonalReportTimelineViewState
    extends ConsumerState<PersonalReportTimelineView> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(DateTime.now());
  }

  String _formatDayLabel(DateTime d) {
    const wdJP = ['月', '火', '水', '木', '金', '土', '日'];
    final wd = wdJP[d.weekday - 1];
    return '${d.month}/${d.day}($wd)';
  }

  void _prevDay() => setState(() => _date = _date.subtract(const Duration(days: 1)));
  void _nextDay() => setState(() => _date = _date.add(const Duration(days: 1)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _refresh() async {
    final q = PersonalReportListQuery(start: _date, end: _date);
    await ref.read(personalReportListProvider(q).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final q = PersonalReportListQuery(start: _date, end: _date);
    final asyncReports = ref.watch(personalReportListProvider(q));

    return Column(
      children: [
        DayHeader(
          label: _formatDayLabel(_date),
          onPrev: _prevDay,
          onNext: _nextDay,
          onPickDate: _pickDate,
        ),
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
                // 表示対象: pending / submitted / locked
                final visible = list.where((r) =>
                    r.status == ReportStatus.pending ||
                    r.status == ReportStatus.submitted ||
                    r.status == ReportStatus.locked).toList();

                int priority(ReportStatus s) {
                  if (s == ReportStatus.pending) return 0;
                  if (s == ReportStatus.submitted) return 1;
                  return 2; // locked
                }

                visible.sort((a, b) {
                  final p = priority(a.status).compareTo(priority(b.status));
                  if (p != 0) return p;
                  final da = (a.submittedAt ?? a.createdAt);
                  final db = (b.submittedAt ?? b.createdAt);
                  return db.compareTo(da);
                });

                if (visible.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    children: const [
                      Center(child: Text('この日の個人日報はありません。')),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final pr = visible[i];
                    final canViewDetail = pr.permissions.canViewDetail;
                    final canDelete = pr.permissions.canDelete;
                    final canApprove = pr.permissions.canApprove;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PersonalReportCard(
                          report: pr,
                          onTapUser: () => _openProfile(pr.user.id),
                          onTapDetail: () => _handleOpenDetail(pr, canViewDetail),
                          showDelete: canDelete,
                          onTapDelete: canDelete ? () => _confirmDelete(pr) : null,
                        ),

                        // ★ 変更申請エリア（カード外・下部）
                        if (pr.status == ReportStatus.pending && canApprove)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  '変更申請',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  onPressed: () => _openPersonalDetail(pr),
                                  child: const Text('訂正'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () {
                                    // 後日実装。今は何もしない（要求どおり）
                                  },
                                  child: const Text('承認'),
                                ),
                              ],
                            ),
                          ),
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

  // ====== handlers ======
  void _handleOpenDetail(PersonalReportModel pr, bool canViewDetail) {
    if (!canViewDetail) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('権限がありません')));
      return;
    }
    _openPersonalDetail(pr);
  }

  Future<void> _confirmDelete(PersonalReportModel pr) async {
    final ok = await showConfirmDialog(
      context: context,
      title: '削除確認',
      message: 'この個人日報を削除します。よろしいですか？',
      okLabel: '削除',
      cancelLabel: 'キャンセル',
    );
    if (!ok) return;

    final q = PersonalReportListQuery(start: _date, end: _date);
    await ref.read(personalReportListProvider(q).notifier).remove(pr.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('削除しました')));
  }

  void _openPersonalDetail(PersonalReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsCreatePage(initialPersonal: report),
      ),
    );
  }

  void _openProfile(int userId) {
    // 既存のプロフィール遷移（プロバイダー側の実装に合わせてください）
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileTabPage(userId: userId)),
    );
  }
}



