import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/models/convInvi_model.dart';
import 'package:frontend/models/conversation_model.dart';

Future<List<ConvInviModel>> fetchConversation(Dio dio) async {
    try {
        final response = await dio.get('chat/conversation/');

        // 明示的にList<Map<String, dynamic>>にキャスト
        final List<dynamic> rawData = response.data;
        final List<ConvInviModel> conversations = rawData
            .map((json) => ConvInviModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return conversations;
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
  int? partnerId, // 相手ユーザーのID
  bool isGroup = false,
  String? title,
  File? iconFile,
}) async {
  try {
    final Map<String, dynamic> data = {
        'is_group': isGroup,
    };

    if (isGroup) {
        if (title == null) {
            throw Exception('タイトルは必須です');
        }

        if (iconFile != null) {
            data.addAll({
            'title': title,
            'icon': await MultipartFile.fromFile(iconFile.path),
            });
        } else {
            data['title'] = title;
        }
    }

    // is_groupがfalse（DM）ならpartnerを追加
    if (!isGroup && partnerId != null) {
        data['partner'] = partnerId;
    }

    final response = await dio.post(
        'chat/conversation/create/',
        data: FormData.fromMap(data),
    );
    return ConversationModel.fromJson(response.data);
  } on DioException catch (e) {
    print('📛 createConversation error: ${e.response?.data}');
    throw Exception('会話の作成に失敗しました');
  }
}


Future<Map<String, dynamic>> deleteConversation({
  required Dio dio,
  required String conversation_id,
}) async {
  try {
      final response = await dio.patch(
        'chat/conversation/$conversation_id/delete/',
        data: {},
        options: Options(
          headers: {'Content-Type': 'application/json'}, // ← 安全・推奨
        ),
      );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('削除に失敗しました（ステータス: ${response.statusCode}）');
    }
  } on DioException catch (e) {
    print('📛 deleteConversation error: ${e.response?.data}');
    throw Exception('会話の削除に失敗しました');
  }
}