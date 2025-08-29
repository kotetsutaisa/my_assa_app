// lib/providers/office/wage_contract_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/models/office/wage_contract_model.dart';
import 'package:frontend/providers/office/employee_detail_summary_provider.dart';

class WageContractListNotifier extends StateNotifier<AsyncValue<List<WageContractModel>>> {
  final Ref ref;
  WageContractListNotifier(this.ref) : super(const AsyncLoading()) { fetch(); }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final list = await fetchWageContracts(dio);
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<WageContractModel> create(WageContractModel model) async {
    final dio = ref.read(dioProvider);
    final created = await createWageContract(dio, model);
    await fetch();
    return created;
  }

  Future<WageContractModel> patch(int id, Map<String, dynamic> patch) async {
    final dio = ref.read(dioProvider);
    final updated = await patchWageContract(dio, id, patch);
    await fetch();
    return updated;
  }
}

final wageContractListProvider = StateNotifierProvider<WageContractListNotifier, AsyncValue<List<WageContractModel>>>(
  (ref) => WageContractListNotifier(ref),
);




// =============================
// ユーザー別 賃金契約の一覧 + 変更操作
// =============================
final userWageContractsProvider = StateNotifierProvider.family<
    UserWageContractsNotifier,
    AsyncValue<List<WageContractModel>>,
    int>((ref, userId) {
  return UserWageContractsNotifier(ref, userId);
});

class UserWageContractsNotifier
    extends StateNotifier<AsyncValue<List<WageContractModel>>> {
  UserWageContractsNotifier(this.ref, this.userId)
      : super(const AsyncLoading()) {
    fetch();
  }

  final Ref ref;
  final int userId;

  /// 一覧取得（?user_id=）
  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final list = await fetchUserWageContracts(dio, userId: userId);
      state = AsyncData(_sorted(list));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => fetch();

  /// 新規作成（POST）
  /// ※ WageContractModel.toCreateJson() に user_id が含まれている前提
  Future<WageContractModel> create({required WageContractModel model}) async {
    final dio = ref.read(dioProvider);
    final created = await createWageContractForUser(dio, model: model);

    // 楽観反映
    final current = state.value ?? const <WageContractModel>[];
    state = AsyncData(_sorted([...current, created]));

    // 現在契約が変わり得るので詳細サマリーを再取得
    ref.invalidate(employeeDetailSummaryProvider(userId));
    return created;
  }

  /// 更新（PATCH）
  Future<WageContractModel> update({
    required int id,
    required Map<String, dynamic> patch,
  }) async {
    final dio = ref.read(dioProvider);
    final updated = await patchWageContractById(dio, id: id, patch: patch);

    // 楽観反映
    final list = [...(state.value ?? const <WageContractModel>[])];
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    state = AsyncData(_sorted(list));

    // 現在契約が変わり得るので詳細サマリーを再取得
    ref.invalidate(employeeDetailSummaryProvider(userId));
    return updated;
  }

  /// 削除（DELETE）
  Future<void> remove({required int id}) async {
    final dio = ref.read(dioProvider);
    await deleteWageContractById(dio, id: id);

    // 楽観反映
    final list = [...(state.value ?? const <WageContractModel>[])];
    list.removeWhere((e) => e.id == id);
    state = AsyncData(_sorted(list));

    // 現在契約が変わり得るので詳細サマリーを再取得
    ref.invalidate(employeeDetailSummaryProvider(userId));
  }

  /// 並び順: 有効開始日(desc) → id(desc)
  List<WageContractModel> _sorted(List<WageContractModel> input) {
    final out = [...input];
    out.sort((a, b) {
      final c1 = b.effectiveFrom.compareTo(a.effectiveFrom);
      if (c1 != 0) return c1;
      return b.id.compareTo(a.id);
    });
    return out;
  }
}
