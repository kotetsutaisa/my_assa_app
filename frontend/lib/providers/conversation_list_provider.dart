// モデルは ConvInviModel のままでOK

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/conversation_api.dart';
import 'package:frontend/api/invitation_api.dart';
import 'package:frontend/api/participant_api.dart';
import 'package:frontend/models/convInvi_model.dart';
import 'package:frontend/models/last_message_model.dart';
import 'package:frontend/providers/dio_provider.dart';

class ConversationListNotifier extends StateNotifier<AsyncValue<List<ConvInviModel>>> {
  final Ref ref;

  ConversationListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetch(); // 初期データ取得
  }

  List<ConvInviModel> _sortByRecent(List<ConvInviModel> items) {
    items.sort((a, b) {
      final aDate = a.conversation?.lastMessage?.createdAt ?? a.conversation!.updatedAt;
      final bDate = b.conversation?.lastMessage?.createdAt ?? b.conversation!.updatedAt;
      return bDate.compareTo(aDate); // 新しい順
    });
    return items;
  }

  Future<void> fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final data = await fetchConversation(dio);
      state = AsyncValue.data(_sortByRecent(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addConversation(ConvInviModel conversation) {
    final newId = conversation.conversation?.id;
    if (newId == null) return;

    state.whenData((list) {
        final exists = list.any((c) => c.conversation?.id == newId);
        if (!exists) {
          final updated = [conversation, ...list];
          state = AsyncValue.data(_sortByRecent(updated));
        }
    });
  }

  void updateLastMessage({
    required String conversationId,
    required LastMessage newMessage,
  }) {
    final currentState = state;
    if (currentState is AsyncData<List<ConvInviModel>>) {
      final updated = currentState.value.map((item) {
        if (item.conversation?.id == conversationId) {
          final updatedConv = item.conversation!.copyWith(
            lastMessage: newMessage,
            updatedAt: newMessage.createdAt ?? DateTime.now(),
          );
          return item.copyWith(conversation: updatedConv);
        }
        return item;
      }).toList();

      // ✅ stateを更新して反映
      state = AsyncValue.data(_sortByRecent(updated));
    }
  }

  // 会話の削除(見た目だけ)
  Future<void> deleteConversationById(String conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      await deleteConversation(dio: dio, conversation_id: conversationId);

      await fetch();
    } catch (e) {
      print('❌ 会話削除エラー: $e');
    }
  }

  // 招待コードの削除
  Future<void> leaveConversationById(String conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      await exitGroup(dio, conversationId);

      await fetch();
    } catch (e) {
      print('❌ グループチャットの退会に失敗: $e');
      rethrow;
    }
  }

  // 招待コードの削除
  Future<void> deleteInviteById(String conversationId) async {
    try {
      final dio = ref.read(dioProvider);
      await deleteInvite(dio, conversationId);

      await fetch();
    } catch (e) {
      print('❌ 招待削除失敗: $e');
      rethrow;
    }
  }


  Future<void> participateInGroup(String conversationId) async {
    try {
        final dio = ref.read(dioProvider);
        await acceptGroupInvitation(
            dio: dio,
            conversationId: conversationId,
        );

        await createParticipant(
            dio: dio,
            conversationId: conversationId
        );

        // 更新後際取得
        await fetch();
    } catch (e) {
        print('❌ グループ参加エラー: $e');
    }
  }
}

// Provider を宣言
final conversationListProvider = StateNotifierProvider<ConversationListNotifier, AsyncValue<List<ConvInviModel>>>(
  (ref) => ConversationListNotifier(ref),
);

