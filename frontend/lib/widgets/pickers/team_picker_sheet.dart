// lib/widgets/pickers/team_picker_sheet.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/team_info_model.dart';
import 'package:frontend/providers/team_list_provider.dart';

/// チーム選択用ボトムシート
/// - showPersonalOption: 先頭に「個人で提出」を表示（null を返す）
/// - allowedTeamIds: 表示を許可するチームIDのホワイトリスト（nullなら全件）
/// - 返却値: TeamInfo?（null=個人）
class TeamPickerSheet extends ConsumerWidget {
  final bool showPersonalOption;

  /// 表示許可するチームIDのホワイトリスト。
  /// - Admin: null を渡す（=全社チーム表示）
  /// - Leader: 自分がリーダーのチームID配列を渡す
  /// - その他: このシート自体を開かせない（親で制御）
  final List<String>? allowedTeamIds;

  const TeamPickerSheet({
    super.key,
    this.showPersonalOption = false,
    this.allowedTeamIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTeams = ref.watch(teamListProvider);
    final maxH = math.min(MediaQuery.of(context).size.height * 0.7, 520.0);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text('提出対象を選択', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: '更新',
                    onPressed: () => ref.refresh(teamListProvider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            if (showPersonalOption)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('個人で提出'),
                onTap: () => Navigator.pop<TeamInfo?>(context, null),
              ),

            Expanded(
              child: asyncTeams.when(
                loading: () => const _LoadingList(),
                error: (e, st) => _ErrorView(
                  message: 'チーム一覧の取得に失敗しました。\n$e',
                  onRetry: () => ref.refresh(teamListProvider),
                ),
                data: (teamsAll) {
                  // allowedTeamIds が指定されていれば、そのID群に含まれるチームだけを表示
                  final teams = (allowedTeamIds == null)
                      ? teamsAll
                      : teamsAll.where((t) => allowedTeamIds!.contains(t.id)).toList();

                  if (teams.isEmpty) {
                    return const _EmptyView(message: '選択できるチームがありません。');
                  }

                  // （任意）見やすさのため、役割や名前で軽く並び替え
                  teams.sort((a, b) {
                    // leader を先頭に、その後 name 昇順
                    int roleScore(String r) => r == 'leader' ? 0 : 1;
                    final rs = roleScore(a.role).compareTo(roleScore(b.role));
                    if (rs != 0) return rs;
                    return a.name.compareTo(b.name);
                  });

                  return ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final t = teams[i];
                      return ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(t.name),
                        subtitle: t.role.isNotEmpty
                            ? Text('あなたの役割: ${_roleLabel(t.role)}')
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop<TeamInfo?>(context, t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'leader':
        return 'リーダー';
      case 'member':
        return 'メンバー';
      default:
        return role;
    }
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

