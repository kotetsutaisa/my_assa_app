// lib/screens/office/employee_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/providers/office/office_employees_provider.dart';
import 'package:frontend/models/office/employee_with_contract_summary_model.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/office/employee_detail_page.dart';
import 'package:frontend/utils/image_helper.dart';
import 'package:frontend/widgets/common/avatar.dart';

class EmployeeListPage extends ConsumerStatefulWidget {
  const EmployeeListPage({super.key});

  @override
  ConsumerState<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends ConsumerState<EmployeeListPage> {
  final _searchCtl = TextEditingController();

  String _formatUpdatedAt(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _openDetail(BuildContext context, int userId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmployeeDetailPage(userId: userId)),
    );
    // 詳細画面で保存成功時は pop(true) で戻る想定
    if (changed == true && mounted) {
      await ref.read(officeEmployeesProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(userProvider);
    final allowed = me?.isAdmin == true || me?.isClerk == true;

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('従業員給料設定')),
        body: const Center(child: Text('権限がありません')),
      );
    }

    final state = ref.watch(officeEmployeesProvider);
    final notifier = ref.read(officeEmployeesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('従業員給料設定'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtl,
              onChanged: notifier.setSearchDebounced,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '氏名 / アカウントID / メールで検索',
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: state.when(
            loading: () => const _ListSkeleton(),
            error: (e, st) => ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 12),
                      Text('読み込みに失敗しました\n$e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: notifier.refresh,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('対象のユーザーがいません')),
                    ],
                  )
                : ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    itemBuilder: (context, index) {
                      final e = items[index];
                      return _EmployeeRow(
                        item: e,
                        resolveImageUrl: resolveImageUrl,
                        formatUpdatedAt: _formatUpdatedAt,
                        onTap: () => _openDetail(context, e.user.id),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.item,
    required this.resolveImageUrl,
    required this.formatUpdatedAt,
    this.onTap,
  });

  final EmployeeWithContractSummary item;
  final String Function(String path) resolveImageUrl;
  final String Function(DateTime? dt) formatUpdatedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final u = item.user;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- アイコン ---
            buildAvatar(
              context: context,
              imageUrl: u.iconimg,
              radius: 22,
              resolveUrl: resolveImageUrl,
            ),
            const SizedBox(width: 16),

            // --- 本文 ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1行目：名前 ・ 所属チーム名 …… 最終更新（右寄せ）
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 左：名前 + チーム名
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.group,
                                size: 16,
                                color:
                                    Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                u.primaryTeamName, // 先頭チーム名
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 右：最終更新
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary),
                          const SizedBox(width: 4),
                          Text(
                            formatUpdatedAt(item.updatedAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 2行目：権限 ・ mainRateLabel
                  Wrap(
                    runSpacing: 6,
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary),
                          const SizedBox(width: 4),
                          Text(
                            u.roleJa, // enum -> 日本語ラベル
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary),
                          const SizedBox(width: 4),
                          Text(
                            item.mainRateLabel ?? '未設定',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.secondary,),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    // セパレータ表示に寄せたローディング
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: const [
            CircleAvatar(),
            SizedBox(width: 12),
            Expanded(
              child: SizedBox(height: 16, child: LinearProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}


