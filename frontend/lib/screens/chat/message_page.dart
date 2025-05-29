import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/providers/message_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/utils/token_manager.dart';
import 'package:frontend/widgets/chat_header.dart';
import 'package:frontend/widgets/chat_input_field.dart'; // ← ここ重要
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MessagePage extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const MessagePage({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  final ScrollController _scrollController = ScrollController();
  late WebSocketChannel _channel;

  @override
void initState() {
  super.initState();
  _connectWebSocket();
}

Future<void> _connectWebSocket() async {
  final roomId = widget.conversation.id;
  final token = await getAccessToken(); // ← JWTトークン取得

  final uri = Uri.parse('$wsApiBaseUrl/ws/chat/$roomId/?token=$token');

  _channel = WebSocketChannel.connect(uri);

  _channel.stream.listen((event) {
    print('📥 WebSocketメッセージ受信: $event');

    final data = jsonDecode(event);

    // --- 既読通知の処理を追加 ---
    if (data['type'] == 'read') {
      final messageId = data['message_id'];

      ref
        .read(messageListProvider(widget.conversation.id).notifier)
        .markMessageAsRead(messageId);

      return;
    }

    // --- 通常の新着メッセージ処理 ---
    final message = MessageModel.fromJson(data);

    ref
      .read(messageListProvider(widget.conversation.id).notifier)
      .addReceivedMessage(message);
  },
  onError: (error) {
    print('❌ WebSocketエラー: $error');
  },
  onDone: () {
    print('🔌 WebSocket接続終了');
  });

  print('✅ WebSocketに接続しました');
}


  @override
  void dispose() {
    _channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  bool isMyMessage(dynamic senderId) {
    final myId = ref.read(userProvider)?.id;
    return senderId.toString() == myId.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageListAsync = ref.watch(messageListProvider(widget.conversation.id));
    final partnerUser = widget.conversation.partner;

    return Scaffold(
      appBar: ChatHeader(
        username: partnerUser?.username ?? '不明なユーザー',
        userIconUrl: partnerUser?.iconimg,
      ),
      body: Column(
        children: [
          Expanded(
            child: messageListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
              data: (messages) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = isMyMessage(msg.sender.id);
                    final text = msg.body['text'] ?? '';
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blueAccent : Colors.grey.shade300,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 18),
                              ),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(msg.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (isMe)
                            Text(
                              msg.isRead ? '既読' : '未読',
                              style: TextStyle(
                                fontSize: 11,
                                color: msg.isRead ? Colors.green : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 入力欄（chat_input_field.dartを使う）
          ChatInputField(
            onSend: (text) async {
              if (text.isEmpty) return;
              print('✅ メッセージ送信: $text');
              // TODO: kindは動的に修正
              await ref
                .read(messageListProvider(widget.conversation.id).notifier)
                .addMessage(kind: 'text', bodyText: text);

              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }
}



