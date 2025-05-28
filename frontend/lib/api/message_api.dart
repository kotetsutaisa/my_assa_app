import 'package:dio/dio.dart';
import 'package:frontend/models/message_model.dart';

// メッセージ一覧取得
Future<List<MessageModel>> fetchMessage(Dio dio, String conversation_id) async {
  try {
    final response = await dio.get('chat/conversation/$conversation_id/message/');
    final List<dynamic> data = response.data;
    return data.map((json) => MessageModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('📛 fetchMessage error: ${e.message}');
    throw Exception('メッセージの取得に失敗しました');
  }
}


// メッセージ作成
Future<MessageModel> createMessage({
  required Dio dio,
  required String conversation_id,
  required String kind,
  required String body,
}) async {
  try {
    final response = await dio.post(
      'chat/conversation/$conversation_id/message/',
      data : {
        'conversation': conversation_id,
        'kind': kind,
        'body': {
          'text': body,
        },
      },
      options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
      ),
    );

    return MessageModel.fromJson(response.data);
  } on DioException catch (e) {
    print('📛 createMessage error: ${e.response?.data}');
    throw Exception('メッセージの作成に失敗しました');
  }
    
}