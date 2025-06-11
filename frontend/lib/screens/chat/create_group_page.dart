import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/company_user_provider.dart';
import 'package:frontend/providers/selected_user_provider.dart';
import 'package:frontend/screens/chat/group_detail_page.dart';
import 'package:frontend/widgets/user_multi_select_list.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() =>
      _CreateGroupPage();
}

class _CreateGroupPage extends ConsumerState<CreateGroupPage> {

  @override
  Widget build(BuildContext context) {
    final companyUsersAsync = ref.watch(companyUserProvider);
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // 戻るときの処理を書く（例：リセット処理）
        if (didPop) {
          ref.read(selectedUsersProvider.notifier).clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('グループチャット作成'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailPage(),
                  ),
                );
              },
              child: Text(
                '次へ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        body: companyUsersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
          data: (users) => Column(
            children: [
              Expanded(
                child: UserMultiSelectList(users: users),
              ),
            ],
          ),
        ),
      ),
    );
  }
}