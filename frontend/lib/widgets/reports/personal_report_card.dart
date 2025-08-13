import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/models/reports/personal_report_model.dart';
import 'package:frontend/models/reports/personal_report_entry_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/widgets/common/avatar.dart';

class PersonalReportCard extends StatelessWidget {
  final PersonalReportModel report;
  final VoidCallback? onTapUser;
  final VoidCallback? onTapDetail;

  /// 権限ルールにより表示する削除ボタン（タイムライン側で判定）
  final bool showDelete;
  final VoidCallback? onTapDelete;

  const PersonalReportCard({
    super.key,
    required this.report,
    this.onTapUser,
    this.onTapDetail,
    this.showDelete = false,
    this.onTapDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 提出表示
    final String submittedAtText = switch (report.status) {
      ReportStatus.pending   => '変更申請中',
      ReportStatus.locked    => '(締め)',
      _ => report.submittedAt != null
          ? DateFormat('HH:mm').format(report.submittedAt!)
          : '未提出',
    };

    // 背景色（pending=淡い黄 / locked=灰、それ以外=通常）
    final Color? cardColor = switch (report.status) {
      ReportStatus.pending => Colors.amber[50],
      ReportStatus.locked  => Theme.of(context).colorScheme.surfaceVariant,
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: cardColor,
      child: InkWell(
        onTap: onTapDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上段：アイコン + ユーザー名 + 提出表示 + (権限時のみ)ゴミ箱
              Row(
                children: [
                  InkWell(
                    onTap: onTapUser,
                    child: buildAvatar(
                      context: context,
                      imageUrl: report.user.iconimg,
                      radius: 18,
                      resolveUrl: (p) => p,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      report.user.username,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDelete) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: '削除',
                          onPressed: onTapDelete,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        submittedAtText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 下段：サイト×作業（右側に「開始〜終了」を表示）
              ..._buildEntryRows(context, report.entries),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEntryRows(
      BuildContext context, List<PersonalReportEntryModel> entries) {
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '明細なし',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ];
    }

    String rowLabel(PersonalReportEntryModel e) {
      final site = e.site.name;
      final work = e.workCategory?.name;
      return (work == null || work.isEmpty) ? '現: $site' : '現: $site　作: $work';
    }

    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return [
      for (var i = 0; i < entries.length; i++) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // 左：現場×作業
              Expanded(
                child: Text(
                  rowLabel(entries[i]),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // 右：時間帯（チームカードと同系統のUI）
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${fmt(entries[i].startTime)} 〜 ${fmt(entries[i].endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (i != entries.length - 1) const Divider(height: 1),
      ],
    ];
  }
}


