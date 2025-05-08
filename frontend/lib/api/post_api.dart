import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';

// 投稿一覧取得API
Future<List<PostModel>> fetchPosts(Dio dio) async {
  try {
    final response = await dio.get('posts/');
    final List<dynamic> jsonList = response.data;
    return jsonList.map((json) => PostModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('投稿一覧取得エラー: ${e.message}');
    throw Exception('投稿の取得に失敗しました');
  }
}



/// --- 新規投稿API（画像付き対応）---
Future<void> createPost({
  required Dio dio,
  required String content,
  required bool isImportant,
  XFile? imageFile,
}) async {
  try {
    final formData = FormData.fromMap({
      'content': content,
      'is_important': isImportant,
      if (imageFile != null)
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
    });

    await dio.post('posts/create/', data: formData);
  } on DioException catch (e) {
    print(' 投稿作成エラー: ${e.message}');
    final msg = e.response?.data['detail'] ?? '投稿の作成に失敗しました';
    throw Exception(msg);
  }
}
