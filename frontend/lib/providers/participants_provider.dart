import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/participant_api.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final participantsProvider = FutureProvider.family<List<SimpleUserModel>, String>((ref, conversationId) async {
  final dio = ref.read(dioProvider);
  return await fetchParticipants(dio, conversationId);
});
