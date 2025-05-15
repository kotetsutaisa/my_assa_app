import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/comment_api.dart';
import '../models/comment_model.dart';
import 'dio_provider.dart';

/// --- family 対応 Notifier ---
class CommentListNotifier
    extends FamilyAsyncNotifier<List<CommentModel>, int> {
  @override
  Future<List<CommentModel>> build(int postId) async {
    final dio = ref.read(dioProvider);
    return fetchComments(dio, postId);
  }

  Future<void> refresh() async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => fetchComments(dio, arg));
    // `arg` で family 引数(postId)を取得できる
  }

  void prependComment(CommentModel c) {
    state = AsyncData([c, ...state.value ?? []]);
  }
}

/// --- Provider 登録 ---
final commentListProvider = AsyncNotifierProvider.family<
    CommentListNotifier, List<CommentModel>, int>(
  CommentListNotifier.new,
);

