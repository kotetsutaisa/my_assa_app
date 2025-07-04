import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final userProfileProvider = FutureProvider.family<UserModel, int>((ref, userId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/users/$userId');
  return UserModel.fromJson(res.data);
});
