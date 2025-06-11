import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/invitation_model.dart';

final invitationProvider =
    StateNotifierProvider<InvitationNotifier, List<InvitationModel>>(
  (ref) => InvitationNotifier(),
);

class InvitationNotifier extends StateNotifier<List<InvitationModel>> {
  InvitationNotifier() : super([]);

  Future<void> fetchInvitations(Dio dio) async {
    final res = await dio.get("/api/invitations/");
    final data = res.data as List;
    state = data.map((json) => InvitationModel.fromJson(json)).toList();
  }

  void remove(String invitationId) {
    state = state.where((i) => i.id != invitationId).toList();
  }

  Future<void> declineInvitation(Dio dio, String conversationId, String invitationId) async {
    try {
      await dio.delete('/chat/conversation/$conversationId/invite/');
      remove(invitationId);
    } catch (e) {
      throw Exception('招待の辞退に失敗しました: $e');
    }
  }

  void add(InvitationModel invitation) {
    state = [invitation, ...state];
  }
}
