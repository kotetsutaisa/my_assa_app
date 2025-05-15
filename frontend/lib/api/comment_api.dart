import 'package:dio/dio.dart';
// 画像付きコメントなら使う
// import 'package:image_picker/image_picker.dart';

import '../models/comment_model.dart';

/// --- 一覧取得 ---
Future<List<CommentModel>> fetchComments(Dio dio, int postId) async {
  final res = await dio.get('posts/$postId/comments/');
  return (res.data as List)
      .map((j) => CommentModel.fromJson(j as Map<String, dynamic>))
      .toList();
}

/// --- 新規作成 ---
Future<CommentModel> createComment({
  required Dio dio,
  required int postId,
  required String content,
}) async {
  final res = await dio.post(
    'posts/$postId/comments/',
    data: {'content': content},
  );
  return CommentModel.fromJson(res.data);
}

/// --- 更新 ---
Future<CommentModel> updateComment({
  required Dio dio,
  required int commentId,
  required String content,
}) async {
  final res = await dio.put(
    'posts/comments/$commentId/',
    data: {'content': content},
  );
  return CommentModel.fromJson(res.data);
}

/// --- 削除 ---
Future<void> deleteComment(Dio dio, int commentId) async {
  await dio.delete('posts/comments/$commentId/');
}
