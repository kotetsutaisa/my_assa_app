import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/company_user_provider.dart';
import 'package:frontend/providers/selected_user_provider.dart';
import 'package:frontend/screens/chat/group_detail_page.dart';
import 'package:frontend/utils/constants.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() =>
      _CreateGroupPage();
}

class _CreateGroupPage extends ConsumerState<CreateGroupPage> {

  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final companyUsersAsync = ref.watch(companyUserProvider);
    final selectedUsers = ref.watch(selectedUsersProvider);
    
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
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = selectedUsers.contains(user);

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.iconimg != null
                          ? CachedNetworkImageProvider(resolveImageUrl(user.iconimg))
                          : null,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: user.iconimg == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(user.username),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          ref.read(selectedUsersProvider.notifier).toggleUser(user);
                        },
                      ),
                      onTap: () {
                        ref.read(selectedUsersProvider.notifier).toggleUser(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}