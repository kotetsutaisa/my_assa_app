import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post_model.dart';
import '../../api/post_api.dart';
import '../../providers/dio_provider.dart'; // ← dioProviderの場所

class PostListNotifier extends AsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    final dio = ref.read(dioProvider);
    return await fetchPosts(dio); // ← Dioを渡す！
  }

  Future<void> refreshPosts() async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => fetchPosts(dio));
  }

  void addPost(PostModel post) {
    state = AsyncData([post, ...state.value ?? []]);
  }

  void updatePost(PostModel updatedPost) {
    final current = state.value ?? [];
    state = AsyncData(
      current.map((p) => p.id == updatedPost.id ? updatedPost : p).toList(),
    );
  }

  void incrementCommentCount(int postId) {
    final current = state.value ?? [];
    state = AsyncData(
      current.map((p) =>
          p.id == postId ? p.copyWith(commentsCount: p.commentsCount + 1) : p
      ).toList(),
    );
  }

}

// --- Provider登録 ---
final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<PostModel>>(() => PostListNotifier());

