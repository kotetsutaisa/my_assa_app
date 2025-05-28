import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/conversation_api.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final conversationListProvider = FutureProvider<List<ConversationModel>>((ref) async {
    final dio = ref.watch(dioProvider);
    return await fetchConversation(dio);
});
