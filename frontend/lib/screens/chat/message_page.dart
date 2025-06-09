import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/message_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/chat/group_settings_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/utils/token_manager.dart';
import 'package:frontend/widgets/chat_header.dart';
import 'package:frontend/widgets/chat_input_field.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frontend/exceptions/message_extensions.dart';


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
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll == 0) return;

      _scrollController.jumpTo(maxScroll); // ← アニメーションなしで一瞬でスクロール
    });
  }


  @override
  Widget build(BuildContext context) {
    final messageListAsync = ref.watch(messageListProvider(widget.conversation.id));
    final partnerUser = widget.conversation.partner;

    // 🟡 ここでキーボードの開閉状態を取得
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 🟢 キーボードが開いていたらスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (keyboardHeight > 0) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: ChatHeader(
        username: widget.conversation.isGroup
            ? widget.conversation.title ?? 'グループ'
            : partnerUser?.username ?? '不明なユーザー',
        userIconUrl: widget.conversation.isGroup
            ? widget.conversation.icon
            : partnerUser?.iconimg,

        // グループのときだけ歯車アイコンを渡す
        trailing: widget.conversation.isGroup
            ? IconButton(
                icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupSettingsPage(conversation: widget.conversation),
                    ),
                  );
                },
              )
            : null,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: messageListAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (messages) {

                  final List<Map<String, dynamic>> decoratedMessages = [];
                    DateTime? lastDate;

                    for (final msg in messages) {
                      final msgDate = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);

                      if (lastDate == null || msgDate != lastDate) {
                        decoratedMessages.add({'type': 'date', 'date': msgDate});
                        lastDate = msgDate;
                      }

                      decoratedMessages.add({'type': 'message', 'message': msg});
                    }

                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      // 2. 入力欄 + 余白ぶん下にスペース
                      bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    itemCount: decoratedMessages.length,
                    itemBuilder: (context, index) {

                      final item = decoratedMessages[index];

                      if (item['type'] == 'date') {
                        final date = item['date'] as DateTime;

                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final yesterday = today.subtract(const Duration(days: 1));
                        final msgDate = DateTime(date.year, date.month, date.day);

                        String label;
                        if (msgDate == today) {
                          label = '今日';
                        } else if (msgDate == yesterday) {
                          label = '昨日';
                        } else {
                          label = DateFormat('M月d日 (E)', 'ja').format(msgDate); // 例: 6月2日 (日)
                        }

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final msg = item['message'] as MessageModel;
                      final isMe = isMyMessage(msg.sender.id);
                      final text = msg.body['text'] ?? '';

                      if (msg.kind == 'system') {
                        // 🟡 システムメッセージ用のUI
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }
                      
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
                              widget.conversation.isGroup
                                ? (msg.readUsers.isNotEmpty
                                  ? Text(
                                      '${msg.readUsers.length}既読',
                                      style: const TextStyle(fontSize: 11, color: Colors.green),
                                    )
                                  : const SizedBox.shrink())

                                : Text(
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
            SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ChatInputField(
                onSend: (text) async {
                  if (text.isEmpty) return;
                  print('✅ メッセージ送信: $text');
                  // TODO: kindは動的に修正
                  
                  final notifier = ref.read(messageListProvider(widget.conversation.id).notifier);

                  // メッセージを送信し、レスポンス（作成されたMessageModel）を取得
                  final newMessage = await notifier.addMessage(
                    kind: 'text',
                    bodyText: text,
                  );

                  // ✅ 会話一覧の状態（lastMessage）を更新
                  ref.read(conversationListProvider.notifier).updateLastMessage(
                    conversationId: widget.conversation.id,
                    newMessage: newMessage.toLastMessage(), // ← MessageModel → LastMessage に変換するメソッドが必要
                  );

                  _scrollToBottom();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



