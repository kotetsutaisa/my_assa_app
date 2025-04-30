import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

// 投稿一覧取得API
Future<List<PostModel>> fetchPosts() async {
  final url = Uri.parse('http://10.0.2.2:8000/api/posts/');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);

    final List<dynamic> jsonList = jsonDecode(decodedBody);

    // Map → PostModelに変換
    return jsonList.map((json) => PostModel.fromJson(json)).toList();
  } else {
    throw Exception('投稿の取得に失敗しました');
  }
}
