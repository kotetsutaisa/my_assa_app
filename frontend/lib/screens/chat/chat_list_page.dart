import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/screens/chat/conversation_create_page.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';

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
                  data: (conversations) => ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: conversation.partner?.iconimg != null
                          ? CircleAvatar(
                              radius: 25,
                              backgroundImage: CachedNetworkImageProvider(
                                resolveImageUrl(conversation.partner!.iconimg!),
                              ),
                              backgroundColor: Colors.grey[200],
                            )
                          : CircleAvatar(
                              radius: 25,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                      
                        title: Text(conversation.partner?.username ?? '不明'),
                        trailing: Text(
                          formatPostDate(conversation.updatedAt.toString()),
                        ),
                        onTap: () => ref.read(currentPageProvider.notifier).state = MessagePage(conversation: conversation),
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


