import 'package:dio/dio.dart';
import 'package:frontend/models/simple_user_model.dart';

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
    print('📛 createConversation error: ${e.response?.data}');
    throw Exception('会話の作成に失敗しました');
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
Future<List<SimpleUserModel>> fetchInviteCandidatesUsers({
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

    final List<dynamic> rawList = response.data;
    return rawList.map((item) => SimpleUserModel.fromJson(item)).toList();
  } on DioException catch (e) {
    print('📛 fetchInviteUsers error: ${e.response?.data}');
    throw Exception('グループ未参加ユーザー一覧取得に失敗しました');
  }
}