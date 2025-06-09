import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/simple_user_model.dart';

class SelectedUsersNotifier extends StateNotifier<List<SimpleUserModel>> {
  SelectedUsersNotifier() : super([]);

  void toggleUser(SimpleUserModel user) {
    if (state.any((u) => u.id == user.id)) {
      state = state.where((u) => u.id != user.id).toList();
    } else {
      state = [...state, user];
    }
  }

  void removeUser(SimpleUserModel user) {
    state = state.where((u) => u.id != user.id).toList();
  }

  void clear() => state = [];
}

final selectedUsersProvider =
    StateNotifierProvider<SelectedUsersNotifier, List<SimpleUserModel>>(
  (ref) => SelectedUsersNotifier(),
);

