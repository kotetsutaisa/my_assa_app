import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/conversation_api.dart';
import 'package:frontend/models/convInvi_model.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/providers/company_user_provider.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/screens/chat/create_group_page.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/utils/constants.dart';

// すでに部屋がある場合の処理はまだ未実装
class ConversationCreatePage extends ConsumerStatefulWidget {
  const ConversationCreatePage({super.key});

  @override
  ConsumerState<ConversationCreatePage> createState() =>
      _ConversationCreatePage();
}

class _ConversationCreatePage extends ConsumerState<ConversationCreatePage> {
  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  Future<void> handleCreateConversation(
    WidgetRef ref, BuildContext context, int partnerId) async {
    final dio = ref.read(dioProvider);

    try {
      final ConversationModel conversation = await createConversation(
        dio: dio,
        partnerId: partnerId,
        isGroup: false
      );

      final ConvInviModel convInvi = ConvInviModel(
        conversation: conversation,
        isInvited: false,
        invitedBy: null,
      );

      ref.read(conversationListProvider.notifier).addConversation(convInvi);

      // まずサブ画面を閉じる
      Navigator.pop(context);

      // チャット画面へ遷移
      ref.read(currentPageProvider.notifier).state = MessagePage(conversation: conversation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('会話の作成に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyUsersAsync = ref.watch(companyUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット作成'),
      ),
      body: companyUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('ユーザー取得エラー: $err')),
        data: (users) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateGroupPage()),
                    );
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text('グループを作成する'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 0.5),
                itemBuilder: (context, index) {
                  final user = users[index];

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
                    subtitle: Text(user.accountId),
                    onTap: () => handleCreateConversation(ref, context, user.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

