import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// UserProvider（StateNotifier）クラス
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null); // 最初はnullで初期化

  void setUser(UserModel user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }

  bool get isAuthenticated => state != null;
}

// グローバルなProviderを作成（これでアプリ中どこでも読める！）
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

