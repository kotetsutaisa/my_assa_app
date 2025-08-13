// /lib/widgets/reports/team_report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/models/reports/team_report_model.dart';
import 'package:frontend/models/reports/team_report_entry_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/widgets/common/avatar.dart';

/// チーム日報カード：
///  - 上段：チーム名（タップで詳細へ） + submitted_at（提出時刻）
///  - 右端：権限ありのときだけゴミ箱アイコン
///  - 下段：サイト×作業でまとめた行。行右の三角で展開し、
///          展開時はメンバーの“上”に「開始〜終了(例: 08:00 〜 17:00)」を表示
class TeamReportCard extends StatelessWidget {
  final TeamReportModel report;
  final Set<String> expandedRowKeys;
  final void Function(String key, bool expanded) onToggleExpand;
  final VoidCallback onTapTeam;
  final VoidCallback onTapDetail;
  final void Function(int userId) onTapMember;

  /// 詳細権限がある時のみ true を渡す（親で判定）
  final bool showDelete;
  final VoidCallback? onTapDelete;

  const TeamReportCard({
    super.key,
    required this.report,
    required this.expandedRowKeys,
    required this.onToggleExpand,
    required this.onTapTeam,
    required this.onTapDetail,
    required this.onTapMember,
    this.showDelete = false,
    this.onTapDelete,
  });

  @override
  Widget build(BuildContext context) {
    // サイト×作業でグルーピング（時間帯の最小開始〜最大終了も集計）
    final grouped = _groupBySiteAndWork(report.entries);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段：チーム名 + 提出時刻 + (権限時のみ)ゴミ箱
            InkWell(
              onTap: onTapTeam,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      report.team.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDelete) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline, size: 24),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: '削除',
                          onPressed: onTapDelete,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        report.submittedAt != null
                            ? DateFormat('MM/dd').format(report.submittedAt!)
                            : '未提出',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 下段：まとめ行
            ...grouped.map((g) {
              final key =
                  '${report.id}::${g.siteId}::${g.workCategoryId ?? "none"}::${g.orderIndex}';
              final expanded = expandedRowKeys.contains(key);
              return Column(
                children: [
                  InkWell(
                    onTap: onTapDetail, // 行タップで詳細へ
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _composeRowTitle(g.siteName, g.workCategoryName),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onToggleExpand(key, !expanded),
                          icon: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 展開時：時間帯(最小開始〜最大終了) + メンバー
                  if (expanded) ...[
                    if (g.earliestStart != null && g.latestEnd != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_fmtTime(g.earliestStart!)} 〜 ${_fmtTime(g.latestEnd!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).primaryColor
                                  ),
                            ),
                          ],
                        ),
                      ),
                    _MembersWrap(
                      members: g.members,
                      onTapMember: onTapMember,
                    ),
                  ],

                  if (!identical(g, grouped.last)) const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _composeRowTitle(String siteName, String? workCategoryName) {
    // 例： 「現: 東京現場　作: 型枠」 / 作業内容が null/空ならサイト名のみ
    return (workCategoryName == null || workCategoryName.isEmpty)
        ? siteName
        : '現: $siteName　作: $workCategoryName';
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// 作成順のまま、サイト×作業でまとめる。
  /// ついでにグループ内の最小開始(earliestStart) と最大終了(latestEnd) を集計
  List<_GroupedRow> _groupBySiteAndWork(List<TeamReportEntryModel> entries) {
    final List<_GroupedRow> result = [];
    final Map<String, _GroupedRow> index = {};

    int order = 0;
    for (final e in entries) {
      // site.id は int/String どちらの可能性もあるため、文字列化して握る
      final siteId = (e.site.id ?? '').toString();
      final wcId = e.workCategory?.id;
      final key = '$siteId::$wcId';

      if (!index.containsKey(key)) {
        final row = _GroupedRow(
          key: key,
          orderIndex: order++,
          siteId: siteId,
          siteName: e.site.name,
          workCategoryId: wcId,
          workCategoryName: e.workCategory?.name,
          earliestStart: e.startTime,
          latestEnd: e.endTime,
          members: <SimpleUserModel>[],
        );
        index[key] = row;
        result.add(row);
      }

      final row = index[key]!;

      // 時刻帯を更新（最小開始 / 最大終了）
      if (row.earliestStart == null ||
          _toMinutes(e.startTime) < _toMinutes(row.earliestStart!)) {
        row.earliestStart = e.startTime;
      }
      if (row.latestEnd == null ||
          _toMinutes(e.endTime) > _toMinutes(row.latestEnd!)) {
        row.latestEnd = e.endTime;
      }

      // メンバー重複を避ける（id でユニーク化）
      if (!row.members.any((m) => m.id == e.member.id)) {
        row.members.add(e.member);
      }
    }

    return result;
  }
}

class _GroupedRow {
  final String key;
  final int orderIndex; // 作成順維持のため
  final String siteId;  // ← String に統一（toStringで変換）
  final String siteName;
  final int? workCategoryId;
  final String? workCategoryName;
  final List<SimpleUserModel> members;

  TimeOfDay? earliestStart; // 最小開始
  TimeOfDay? latestEnd;     // 最大終了

  _GroupedRow({
    required this.key,
    required this.orderIndex,
    required this.siteId,
    required this.siteName,
    required this.workCategoryId,
    required this.workCategoryName,
    required this.members,
    this.earliestStart,
    this.latestEnd,
  });
}

class _MembersWrap extends StatelessWidget {
  final List<SimpleUserModel> members;
  final void Function(int userId) onTapMember;
  const _MembersWrap({
    required this.members,
    required this.onTapMember,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 12,
            runSpacing: 10,
            children: members.map((m) {
              return InkWell(
                onTap: () => onTapMember(m.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildAvatar(
                      context: context,
                      imageUrl: m.iconimg,
                      radius: 18,
                      resolveUrl: (p) => p, // 必要に応じて resolveImageUrl に差し替え
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 72,
                      child: Text(
                        m.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}



