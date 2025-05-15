import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';

// 投稿一覧取得
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

// 自分の投稿一覧取得
Future<List<PostModel>> fetchMyPosts(Dio dio) async {
  final res = await dio.get('posts/', queryParameters: {'mine': 'true'});
  return (res.data as List)
      .map((j) => PostModel.fromJson(j as Map<String, dynamic>))
      .toList();
}


/// --- 新規投稿API（画像付き対応）---
Future<void> createPost({
  required Dio dio,
  required String content,
  required bool isImportant,
  required List<XFile> imageFiles,
}) async {
  final formData = FormData();

  // 本文・フラグ
  formData.fields
    ..add(MapEntry('content', content))
    ..add(MapEntry('is_important', isImportant.toString()));

  // 画像(最大4枚)  ★キーはすべて 'images'
  for (final file in imageFiles.take(4)) {
    formData.files.add(
      MapEntry(
        'images',                // ←★ここを固定にする
        await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      ),
    );
  }

  await dio.post('posts/create/', data: formData);
}


// --- いいねトグル ---
Future<PostModel> toggleLike(Dio dio, int postId) async {
  final res = await dio.post('posts/$postId/like/');
  return PostModel.fromJson(res.data);
}


// --- 既読トグル ---
Future<PostModel> markAsRead(Dio dio, int postId) async {
  final res = await dio.post('posts/$postId/read/');
  return PostModel.fromJson(res.data);
}
