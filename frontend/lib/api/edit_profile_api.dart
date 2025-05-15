import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/dio_provider.dart';

/// プロフィール編集API
Future<UserModel> updateProfile({
  required WidgetRef ref,
  required String username,
  required String accountId,
  required String bio,
  File? iconImage, // 画像はオプション
}) async {
  final dio = ref.watch(dioProvider);

  final formData = FormData.fromMap({
    'username': username.trim(),
    'account_id': accountId.trim(),
    'bio': bio.trim(),
    if (iconImage != null)
      'iconimg': await MultipartFile.fromFile(
        iconImage.path,
        filename: iconImage.path.split('/').last,
      ),
  });

  try {
    final response = await dio.put(
      'users/current/update/',
      data: formData,
    );

    final userJson = response.data as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  } on DioException catch (e) {
    final msg = e.response?.data.toString() ?? 'プロフィールの更新に失敗しました';
    throw Exception(msg);
  }
}
