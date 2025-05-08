import 'package:dio/dio.dart';
import 'package:frontend/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --- 保存 ---
Future<void> saveTokens(String accessToken, String refreshToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', accessToken);
  await prefs.setString('refresh_token', refreshToken);
}

/// --- 読み込み ---
Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}

Future<String?> getRefreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('refresh_token');
}

/// --- 削除 ---
Future<void> deleteTokens() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
}

/// --- ログイン済みかどうか ---
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('access_token');
}

/// --- リフレッシュトークンでアクセストークンを再取得（Dio版） ---
Future<bool> refreshAccessToken() async {
  try {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      print('★ リフレッシュトークンが存在しない');
      return false;
    }

    final dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: apiBaseUrl,
      ),
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    final response = await dio.post(
      'users/token/refresh/',
      data: {'refresh': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final newAccessToken = data['access'];
      final newRefreshToken = data['refresh'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccessToken);
      await prefs.setString('refresh_token', newRefreshToken);

      print('★ アクセストークン更新成功: $newAccessToken');
      return true;
    } else {
      print('★ リフレッシュ失敗: ${response.statusCode}');
      print('★ エラー内容: ${response.data}');
      return false;
    }
  } on DioException catch (e) {
    print('❌ Dio通信エラー: ${e.message}');
    return false;
  }
}


