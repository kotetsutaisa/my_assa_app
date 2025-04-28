import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 保存
Future<void> saveTokens(String accessToken, String refreshToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', accessToken);
  await prefs.setString('refresh_token', refreshToken);
}

// 読み込み
Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}

Future<String?> getRefreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('refresh_token');
}

// 削除
Future<void> deleteTokens() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
}

// ログイン済みかどうか
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('access_token');
}


/// リフレッシュトークンでアクセストークンを再取得する
Future<bool> refreshAccessToken() async {
  try {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      print('★ リフレッシュトークンが存在しない');
      return false;
    }

    const BASE_URL = 'http://10.0.2.2:8000'; // ← エミュ用URL

    final response = await http.post(
      Uri.parse('$BASE_URL/api/users/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final resJson = jsonDecode(response.body);
      final newAccessToken = resJson['access'];
      final newRefreshToken = resJson['refresh'];

      // 新しいアクセストークンを保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccessToken);
      await prefs.setString('refresh_token', newRefreshToken);

      print('★ アクセストークン更新成功: $newAccessToken');
      return true;
    } else {
      print('★ リフレッシュ失敗: ${response.statusCode}');
      print('★ リフレッシュエラーメッセージ: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ リフレッシュ通信エラー: $e');
    return false;
  }
}

