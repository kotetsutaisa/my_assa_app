import 'package:dio/dio.dart';
import 'package:frontend/models/simple_user_model.dart';

Future<Map<String, dynamic>> createParticipant({
  required Dio dio,
  required String conversationId,
}) async {
  try {
    final response = await dio.post(
    'chat/conversation/$conversationId/participant/',
    data: {},
    options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
    ),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    print('📛 createParticipant error: ${e.response?.data}');
    throw Exception('participantの作成に失敗しました');
  }
}


Future<List<SimpleUserModel>> fetchParticipants(Dio dio, String conversationId) async {
  final response = await dio.get('chat/conversation/$conversationId/participant/');
  return (response.data as List).map((e) => SimpleUserModel.fromJson(e)).toList();
}
