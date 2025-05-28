import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../api/message_api.dart' as messageApi;       // fetchMessage がある場所
import '../providers/dio_provider.dart'; // dioProvider の定義

class MessageListNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final Ref ref;
  final String conversation_id;

  MessageListNotifier(this.ref, this.conversation_id) : super(const AsyncValue.loading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    final dio = ref.read(dioProvider);
    try {
      final message = await messageApi.fetchMessage(dio, conversation_id);
      state = AsyncValue.data(message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMessage({
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
      // 最新の state に追加（先頭 or 末尾どちらでもOK）
      final current = state.value ?? [];
      state = AsyncValue.data([...current, newMessage]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addReceivedMessage(MessageModel message) {
    final current = state.value ?? [];
    state = AsyncValue.data([...current, message]);
  }
}

final messageListProvider = StateNotifierProvider.family<
  MessageListNotifier, AsyncValue<List<MessageModel>>, String>(
    (ref, conversation_id) => MessageListNotifier(ref, conversation_id)
);
