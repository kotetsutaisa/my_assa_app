import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/schedule_api.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/dio_provider.dart';

class WorkCategoryListNotifier extends AsyncNotifier<List<WorkCategoryModel>> {
  @override
  Future<List<WorkCategoryModel>> build() async {
    final dio = ref.read(dioProvider);
    return await fetchWorkCategories(dio);
  }

  Future<void> addWorkCategory(String name) async {
    final dio = ref.read(dioProvider);
    await createWorkCategory(dio, name);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await fetchWorkCategories(dio);
    });
  }

  Future<void> remove(int id) async {
    final dio = ref.read(dioProvider);
    await deleteWorkCategory(dio, id);

    // 削除後に再読み込み
    state = const AsyncLoading();
    state = AsyncValue.data(await fetchWorkCategories(dio));
  }
}

final workCategoryListProvider =
    AsyncNotifierProvider<WorkCategoryListNotifier, List<WorkCategoryModel>>(
        () => WorkCategoryListNotifier());
