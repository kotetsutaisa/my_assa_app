import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import '../utils/token_manager.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:frontend/providers/dio_provider.dart';

/// ユーザー登録APIを叩く関数（POST）
/// 必要なユーザー情報をJSON形式で送信し、ステータス201で成功とみなす
Future<Map<String, String>> registerUser({
  required WidgetRef ref,
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
  print('🟢 登録APIに送信: $username, $accountId, $email');

  if (!hasLetter || !hasNumber) {
    throw Exception('パスワードには英字と数字の両方を含めてください');
  }

  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.post('users/register/', data: {
      'username': username.trim(),
      'account_id': accountId.trim(),
      'email': email.trim(),
      'password': password,
    });

    final resJson = response.data;
    return {
      'access': resJson['access'],
      'refresh': resJson['refresh'],
    };

  } on DioException catch(e) {
    print('❌ 登録失敗: ${e.response?.data}');
    throw Exception(e.response?.data.toString() ?? '登録に失敗しました');
  }
}

/// ログインAPI
/// 成功時：アクセストークンを返す
/// 失敗時：Exception を throw
Future<Map<String, String>> loginUser({
  required WidgetRef ref,
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

  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.post('users/token/', data: {
      'email': email.trim(),
      'password': password,
    });

    final resJson = response.data;
    return {
      'access': resJson['access'],
      'refresh': resJson['refresh'],
    };
  } on DioException catch (e) {
    throw Exception(e.response?.data.toString() ?? 'ログインに失敗しました');
  }
}

Future<void> fetchCurrentUser(BuildContext context, WidgetRef ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('users/current/');

    final userJson = response.data['user'];
    final user = UserModel.fromJson(userJson);
    ref.read(userProvider.notifier).setUser(user);

    // ✅ 会社情報あり/なしで分岐
    if (user.company == null) {
      // 会社未所属
      Navigator.pushReplacementNamed(context, '/company/top');
    } else if (!user.company!.isApproved) {
      // 申請中（承認待ち）
      Navigator.pushReplacementNamed(context, '/company/pending');
    } else {
      // 承認済み → ホーム画面へ
      Navigator.pushReplacementNamed(context, '/home');
    }

  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        await fetchCurrentUser(context, ref);
      } else {
        await deleteTokens();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      print('ユーザー取得失敗: ${e.response?.statusCode}');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

