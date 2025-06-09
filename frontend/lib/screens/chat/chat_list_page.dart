import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/screens/chat/conversation_create_page.dart';
import 'package:frontend/screens/chat/invite_message_page.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPage();
}

class _ChatListPage extends ConsumerState<ChatListPage> {

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      body: Stack(
        children : [
          Column(
            children: [
              Center(
                child: SubHeader(
                  title: 'チャット',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              Expanded(
                child: conversationsAsync.when(
                  data: (conversationItems) => ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversationItems.length,
                    itemBuilder: (context, index) {
                      final item = conversationItems[index];

                      return item.conversation!.isGroup
                        ? item.isInvited
                          ? ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              leading: item.conversation?.icon != null
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage: CachedNetworkImageProvider(
                                      resolveImageUrl(item.conversation!.icon!),
                                    ),
                                    backgroundColor: Colors.grey[200],
                                  )
                                : CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                            
                              title: Text(item.conversation?.title ?? '不明'),
                              subtitle: Text(
                                '${item.invitedBy?.username ?? '不明なユーザー'}さんから招待が届いています',
                              ),
                              trailing: Text(
                                formatPostDate(item.conversation!.updatedAt.toString()),
                              ),
                              onTap: () => ref.read(currentPageProvider.notifier).state = InviteMessagePage(invite: item),
                            )

                          : Slidable(
                              key: ValueKey(item.conversation?.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(), // ← スムーズな横スライド
                                extentRatio: 0.175,            // ← スライド幅（25%だけスライド）
                                children: [
                                  SlidableAction(
                                    onPressed: (_) async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20.0), // ここで角の丸さを調整
                                          ),
                                          content: Padding(
                                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                            child: const Text('このチャットを削除します。\nよろしいですか？'),
                                          ),
                                          actions: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('キャンセル'),
                                                  ),
                                                ),
                                                const SizedBox(width: 8), // ボタン間のスペース
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('削除'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          try {
                                            // 一覧を更新
                                            await ref.read(conversationListProvider.notifier).deleteConversationById(item.conversation!.id);

                                            // 完了メッセージを表示（任意）
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('チャットを削除しました')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('削除に失敗しました: $e')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('削除に失敗しました: $e')),
                                          );
                                        }
                                      }
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: '削除',
                                  ),
                                ],
                              ),

                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                leading: item.conversation?.icon != null
                                  ? CircleAvatar(
                                      radius: 25,
                                      backgroundImage: CachedNetworkImageProvider(
                                        resolveImageUrl(item.conversation!.icon!),
                                      ),
                                      backgroundColor: Colors.grey[200],
                                    )
                                  : CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Theme.of(context).primaryColor,
                                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                                    ),
                              
                                title: Text(item.conversation?.title ?? '不明'),
                                subtitle: Text(item.conversation?.lastMessage?.content ?? ''),
                                trailing: Text(
                                  formatPostDate(
                                    item.conversation?.lastMessage?.createdAt.toString() 
                                    ?? 
                                    item.conversation!.updatedAt.toString()
                                  ),
                                ),
                                onTap: () => ref.read(currentPageProvider.notifier).state = MessagePage(conversation: item.conversation!),
                              ),
                            )

                        : Slidable(
                            key: ValueKey(item.conversation?.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(), // ← スムーズな横スライド
                              extentRatio: 0.175,            // ← スライド幅（25%だけスライド）
                              children: [
                                SlidableAction(
                                  onPressed: (_) async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0), // ここで角の丸さを調整
                                        ),
                                        content: Padding(
                                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                          child: const Text('このチャットを削除します。\nよろしいですか？'),
                                        ),
                                        actions: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('キャンセル'),
                                                ),
                                              ),
                                              const SizedBox(width: 8), // ボタン間のスペース
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('削除'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // 一覧を更新
                                        await ref.read(conversationListProvider.notifier).deleteConversationById(item.conversation!.id);

                                        // 完了メッセージを表示（任意）
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('チャットを削除しました')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('削除に失敗しました: $e')),
                                        );
                                      }
                                    }
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '削除',
                                ),
                              ],
                            ),

                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              leading: item.conversation?.partner?.iconimg != null
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage: CachedNetworkImageProvider(
                                      resolveImageUrl(item.conversation!.partner!.iconimg!),
                                    ),
                                    backgroundColor: Colors.grey[200],
                                  )
                                : CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                            
                              title: Text(item.conversation?.partner?.username ?? '不明'),
                              subtitle: Text(item.conversation?.lastMessage?.content ?? ''),
                              trailing: Text(
                                formatPostDate(
                                  item.conversation?.lastMessage?.createdAt?.toString() ??
                                  item.conversation!.updatedAt.toString(),
                                ),
                              ),
                              onTap: () => ref.read(currentPageProvider.notifier).state = MessagePage(conversation: item.conversation!),
                            ),
                          );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('エラー: $err')),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 15,
            right: 15,
            child: PostButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConversationCreatePage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


