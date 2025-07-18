import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../api/resource_api.dart';
import '../models/resource_model.dart';
import 'dio_provider.dart';

/// 一覧＋ CRUD をまとめて扱う StateNotifier
class ResourceListNotifier
    extends StateNotifier<AsyncValue<List<ResourceModel>>> {
  final Ref ref;

  ResourceListNotifier(this.ref) : super(const AsyncValue.loading());

  // ---------------- 取得 ----------------
  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final list = await fetchResources(dio);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------- 作成 ----------------
  Future<void> add(ResourceModel newResource) async {
    final dio = ref.read(dioProvider);
    try {
      final created = await createResource(dio, newResource);
      // 即時反映（バックエンド再取得でも OK だが通信削減）
      final cur = state.value ?? [];
      state = AsyncValue.data([...cur, created]);
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ---------------- 更新 ----------------
  Future<void> update({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      final updated = await updateResource(dio,
          resourceId: id, payload: patch);

      final list = (state.value ?? [])
          .map((r) => r.id == id ? updated : r)
          .toList(growable: false);

      state = AsyncValue.data(list);
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ---------------- 削除 ----------------
  Future<void> remove(String id) async {
    final dio = ref.read(dioProvider);
    try {
      await deleteResource(dio, id);
      final list =
          (state.value ?? []).where((r) => r.id != id).toList(growable: false);
      state = AsyncValue.data(list);
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Riverpod プロバイダー
final resourceListProvider = StateNotifierProvider<ResourceListNotifier,
    AsyncValue<List<ResourceModel>>>(
  (ref) => ResourceListNotifier(ref)..fetch(),
);
