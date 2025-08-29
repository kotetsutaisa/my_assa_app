import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/models/office/employee_with_contract_summary_model.dart';

final officeEmployeesProvider = StateNotifierProvider.autoDispose<
    OfficeEmployeesNotifier,
    AsyncValue<List<EmployeeWithContractSummary>>>(
  (ref) => OfficeEmployeesNotifier(ref),
);

class OfficeEmployeesNotifier
    extends StateNotifier<AsyncValue<List<EmployeeWithContractSummary>>> {
  OfficeEmployeesNotifier(this.ref) : super(const AsyncLoading()) {
    fetch(); // 初回ロード
  }

  final Ref ref;

  String? _q;
  String _ordering = '-updated_at';

  // 検索ワードのデバウンス用
  Timer? _debounce;

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final Dio dio = ref.read(dioProvider);
      final list = await fetchOfficeEmployees(
        dio,
        q: _q,
        ordering: _ordering,
        // page/pageSize は将来追加
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();

  void setOrdering(String ordering) {
    if (_ordering == ordering) return;
    _ordering = ordering;
    fetch();
  }

  void setSearchImmediate(String? q) {
    _q = (q == null || q.trim().isEmpty) ? null : q.trim();
    fetch();
  }

  // 入力欄用：300ms デバウンス
  void setSearchDebounced(String? q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setSearchImmediate(q);
    });
  }

  /// 詳細保存後に、一覧の「要約」だけを更新（楽観的反映）
  void updateSummary({
    required int userId,
    String? mainRateLabel,
    DateTime? updatedAt,
  }) {
    final current = state.value;
    if (current == null) return;
    final idx = current.indexWhere((e) => e.user.id == userId);
    if (idx < 0) return;

    final updated = current.toList(growable: false);
    final old = updated[idx];
    updated[idx] = old.copyWith(
      mainRateLabel: mainRateLabel ?? old.mainRateLabel,
      updatedAt: updatedAt ?? old.updatedAt,
    );
    state = AsyncValue.data(updated);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
