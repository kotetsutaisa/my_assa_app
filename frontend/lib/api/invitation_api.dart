import 'package:dio/dio.dart';
import 'package:frontend/models/candidate_user_model.dart';

// --- チャットグループに招待する処理 ---
Future<Map<String, dynamic>> createInvite({
  required Dio dio,
  required String conversationId,
  required List<int> partnerIds,
}) async {
  try {
    final response = await dio.post(
    'chat/conversation/$conversationId/invite/',
    data: {
      'partners': partnerIds,
    },
    options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
    ),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    print('📛 createInvite error: ${e.response?.data}');
    throw Exception('グループチャットの招待に失敗しました');
  }
}

// --- グループに参加する処理 ---
Future<Map<String, dynamic>> acceptGroupInvitation({
  required Dio dio,
  required String conversationId,
}) async {
  try {
    final response = await dio.patch(
      'chat/conversation/$conversationId/invite/',
      data: {
        'is_participated': true,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
      ),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    print('📛 accessInvite error: ${e.response?.data}');
    throw Exception('グループチャットの参加に失敗しました');
  }
}

// --- グループに未参加のユーザー一覧取得 ---
Future<List<CandidateUserModel>> fetchInviteCandidatesUsers({
  required Dio dio,
  required String conversationId,
}) async {
  try {
    final response = await dio.get(
      'chat/conversation/$conversationId/invite/',
      options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
      ),
    );

    final List<dynamic> data = response.data;
    return data.map((json) => CandidateUserModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('📛 fetchInviteUsers error: ${e.response?.data}');
    throw Exception('グループ未参加ユーザー一覧取得に失敗しました');
  }
}

// 招待コードの削除
Future<void> deleteInvite(Dio dio, String conversationId) async {
  try {
    await dio.delete('/chat/conversation/$conversationId/invite/');
  } catch (e) {
    print('❌ 招待の削除に失敗しました: $e');
    rethrow;
  }
}