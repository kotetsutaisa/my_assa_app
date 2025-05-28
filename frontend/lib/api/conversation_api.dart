import 'package:dio/dio.dart';
import 'package:frontend/models/conversation_model.dart';

Future<List<ConversationModel>> fetchConversation(Dio dio) async {
    try {
        final response = await dio.get('chat/conversation/');
        final List<dynamic> data = response.data;
        return data.map((json) => ConversationModel.fromJson(json)).toList();
    } on DioException catch (e) {
        print('📛 fetchConversation error: ${e.message}');
        throw Exception('会話一覧の取得に失敗しました');
    } catch (e) {
        print('📛 予期しないエラー: $e');
        throw Exception('予期しないエラーが発生しました');
    }
}


Future<ConversationModel> createConversation({
  required Dio dio,
  required int partnerId, // 相手ユーザーのID
}) async {
  try {
    final response = await dio.post(
    'chat/conversation/',
    data: {
        'is_group': false,
        'partner': partnerId,
    },
    options: Options(
        headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
    ),
    );

    return ConversationModel.fromJson(response.data);
  } on DioException catch (e) {
    print('📛 createConversation error: ${e.response?.data}');
    throw Exception('会話の作成に失敗しました');
  }
}
