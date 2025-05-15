import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/post_api.dart';
import '../models/post_model.dart';
import '../providers/dio_provider.dart';
import '../providers/user_provider.dart';

class MyPostListNotifier extends AsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    // ① 認証ユーザーを取得
    final me = ref.watch(userProvider);
    if (me == null) return [];            // 未ログインなら空配列

    // ② 既存の fetchPosts() を使って一括取得（エンドポイント追加が最小工数）
    final dio   = ref.read(dioProvider);
    return await fetchMyPosts(dio);
  }

  /* 任意：再読み込み */
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /* 任意：タイムライン側から呼ぶ追加メソッド */
  void prepend(PostModel p) {
    state = AsyncData([p, ...state.value ?? []]);
  }

  /* 任意：いいね／既読／コメント数などを差し替え */
  void updatePost(PostModel updated) {
    state = AsyncData(
      (state.value ?? [])
          .map((p) => p.id == updated.id ? updated : p)
          .toList(),
    );
  }
}

/* Provider 登録 */
final myPostListProvider =
    AsyncNotifierProvider<MyPostListNotifier, List<PostModel>>(
  MyPostListNotifier.new,
);