import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/invitation_api.dart';
import 'package:frontend/models/candidate_user_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final inviteCandidatesUserProvider = FutureProvider.family<List<CandidateUserModel>, String>((ref, conversationId) async {
  final dio = ref.read(dioProvider);
  return fetchInviteCandidatesUsers(dio: dio, conversationId: conversationId);
});