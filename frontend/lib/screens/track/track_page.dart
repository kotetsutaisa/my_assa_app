import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/resource_model.dart';
import 'package:frontend/providers/resource_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/track/resource_detail_page.dart';
import 'package:frontend/screens/track/resource_form_page.dart';  // ResourceListNotifier / resourceListProvider
// import 'package:frontend/providers/current_user_provider.dart'; // 権限チェックで使うなら

/// 搬入・搬出（共有リソース）一覧ページ
class TrackPage extends ConsumerWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourceListProvider);

    Future<void> _refresh() async {
      await ref.read(resourceListProvider.notifier).fetch();
    }

    final body = resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error  : (e, st) => _ErrorView(
        message : '読み込みに失敗しました',
        detail  : '$e',
        onRetry : _refresh,
      ),
      data   : (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('登録された車両はありません')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _ResourceTile(resource: list[i]),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('車両'),
      ),
      body: body,
      floatingActionButton: AddFab(), // 権限チェックはFAB内で
    );
  }
}

/* ────────────────────────────────────────────────────────────── */
/*  ListTile                                                       */
/* ────────────────────────────────────────────────────────────── */

class _ResourceTile extends StatelessWidget {
  final ResourceModel resource;
  const _ResourceTile({required this.resource});

  @override
  Widget build(BuildContext context) {
    // サブタイトル構築（存在する要素だけ）
    final parts = <String>[];

    final catName = resource.category?.name;
    if (catName != null && catName.isNotEmpty) {
      parts.add(catName);
    }
    if (resource.plateNo != null && resource.plateNo!.isNotEmpty) {
      parts.add('ナンバー: ${resource.plateNo}');
    }
    if (resource.capacityKg != null) {
      parts.add('積載: ${resource.capacityKg}kg');
    }

    final subtitle = parts.isEmpty ? null : parts.join(' / ');

    return ListTile(
      title   : Text(resource.name),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap   : () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResourceDetailPage(resource: resource),
        ));
      },
    );
  }
}

/* ────────────────────────────────────────────────────────────── */
/*  エラー表示                                                     */
/* ────────────────────────────────────────────────────────────── */

class _ErrorView extends StatelessWidget {
  final String message;
  final String? detail;
  final Future<void> Function() onRetry;
  const _ErrorView({
    required this.message,
    this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: textTheme.bodyLarge),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────── */
/*  追加FAB（権限チェック仮置き）                                  */
/* ────────────────────────────────────────────────────────────── */

class AddFab extends ConsumerWidget {
  const AddFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // ❶ ログインしていない or 権限なし → ボタン非表示
    if (user == null || !user.canManageResources) {
      return const SizedBox.shrink();
    }

    // ❷ 権限 OK → ボタン表示
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResourceFormPage()),
        );
      },
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, size: 30, color: Colors.white),
    );
  }
}

