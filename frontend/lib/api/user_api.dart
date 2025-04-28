import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../utils/token_manager.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';


/// ユーザー登録APIを叩く関数（POST）
/// 必要なユーザー情報をJSON形式で送信し、ステータス201で成功とみなす
Future<Map<String, String>> registerUser({
  required String username, // ユーザーの名前
  required String accountId, // ユーザーのアカウントID（@xxxx形式）
  required String email, // メールアドレス（ログイン用）
  required String password, // パスワード
}) async {
  // --- フロント側バリデーション ---
  final trimmedName = username.trim();
  if (trimmedName.isEmpty || trimmedName.length < 2) {
    throw Exception('名前は2文字以上で入力してください');
  }

  if (!accountId.startsWith('@') || accountId.length < 8) {
    throw Exception('アカウントIDは「@」で始まり8文字以上で入力してください');
  }

  // 正しいメールアドレス形式のチェック
  final trimmedEmail = email.trim();
  final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$");
  if (!emailRegex.hasMatch(trimmedEmail)) {
    throw Exception('正しいメールアドレス形式ではありません');
  }

  // パスワードの形式チェック
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
  final hasNumber = RegExp(r'\d').hasMatch(password);

  if (!hasLetter || !hasNumber) {
    throw Exception('パスワードには英字と数字の両方を含めてください');
  }

  const BASE_URL = 'http://172.20.10.2:8000';

  // ★ 本番環境ではBASE_URLなどを使って変数化する（今は開発用URL）
  final url = Uri.parse('$BASE_URL/api/users/register/');

  try {
    // APIにPOSTリクエスト送信（Content-Type: JSONで送る）
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'account_id': accountId,
        'email': email,
        'password': password,
      }),
    );

    // レスポンスのステータスコードを確認
    if (response.statusCode == 201) {
      final resJson = jsonDecode(response.body);
      final accessToken = resJson['access'];
      final refreshToken = resJson['refresh'];
      return {
        'access': accessToken,
        'refresh': refreshToken,
      };
    } else {
      // サーバーからのエラーメッセージをパースして表示
      final resJson = jsonDecode(response.body);
      throw Exception(resJson.toString());
    }
  } catch (e) {
    print('❌ 通信エラー: $e');
    throw Exception('登録に失敗しました: $e');
  }
}

/// ログインAPI
/// 成功時：アクセストークンを返す
/// 失敗時：Exception を throw
Future<Map<String, String>> loginUser({
  required String email,
  required String password,
}) async {
  final trimmedEmail = email.trim();
  final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$");
  if (!emailRegex.hasMatch(trimmedEmail)) {
    throw Exception('正しいメールアドレスを入力してください');
  }

  if (password.length < 8) {
    throw Exception('パスワードは8文字以上で入力してください');
  }

  const BASE_URL = 'http://10.0.2.2:8000'; // ← PCエミュレータ用

  final url = Uri.parse('$BASE_URL/api/users/token/');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': trimmedEmail, 'password': password}),
    );

    if (response.statusCode == 200) {
      final resJson = jsonDecode(response.body);
      final accessToken = resJson['access'];
      final refreshToken = resJson['refresh'];
      print('✅ ログイン成功！アクセストークン: $accessToken');
      return {
        'access': accessToken,
        'refresh': refreshToken,
      };
    } else {
      final resJson = jsonDecode(response.body);
      throw Exception(resJson.toString());
    }
  } catch (e) {
    print('❌ ログイン通信エラー: $e');
    throw Exception('ログインに失敗しました: $e');
  }
}


/// ログインユーザー取得API
Future<void> fetchCurrentUser(BuildContext context, WidgetRef ref) async {
  // トークンを取得
  final token = await getAccessToken();

  // トークンがなければログイン画面へ
  if (token == null) {
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  // ログインユーザー情報を取得
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/api/users/current/'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    // jsonをMapに変換
    final json = jsonDecode(response.body);
    // UserModelにMap userを渡しインスタンス化
    final user = UserModel.fromJson(json['user']);

    // RiverpodのUserProviderにセット
    ref.read(userProvider.notifier).setUser(user);

    // userが確実に反映されてから遷移（フレーム待つ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });

  } else if (response.statusCode == 401) {

    print('★ アクセストークン期限切れ → リフレッシュトークンで更新試行');
    
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      // 再取得できたら、もう一回自分自身を呼び出す
      print('★ アクセストークン更新成功 → fetchCurrentUserをリトライ');
      await fetchCurrentUser(context, ref);

    } else {
      // 失敗したらトークン削除してログイン画面へ
      await deleteTokens();
      Navigator.pushReplacementNamed(context, '/login');
    }
    
  } else {
    print('ユーザー取得失敗: ${response.statusCode}');
  }
}
