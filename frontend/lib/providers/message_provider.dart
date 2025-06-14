import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../api/message_api.dart' as messageApi;       // fetchMessage がある場所
import '../providers/dio_provider.dart'; // dioProvider の定義

class MessageListNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final Ref ref;
  final String conversation_id;

  MessageListNotifier(this.ref, this.conversation_id) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    final dio = ref.read(dioProvider);
    try {
      final message = await messageApi.fetchMessage(dio, conversation_id);
      state = AsyncValue.data(message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<MessageModel> addMessage({
    required String kind,
    required String bodyText,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      final newMessage = await messageApi.createMessage(
        dio: dio,
        conversation_id: conversation_id,
        kind: kind,
        body: bodyText,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([...current, newMessage]);

      return newMessage; // ✅ 正常時は必ず返す
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // ✅ 必ず再スローすることで return しない状態を回避
    }
  }


  void addReceivedMessage(MessageModel message) {
    final current = state.value ?? [];
    state = AsyncValue.data([...current, message]);
  }

  void markMessageAsRead(String messageId) {
    final current = state.value ?? [];

    state = AsyncValue.data([
      for (final msg in current)
        if (msg.id == messageId)
          msg.copyWith(isRead: true)
        else
          msg
    ]);
  }
}

final messageListProvider = StateNotifierProvider.family<
  MessageListNotifier, AsyncValue<List<MessageModel>>, String>(
    (ref, conversation_id) => MessageListNotifier(ref, conversation_id)
);
