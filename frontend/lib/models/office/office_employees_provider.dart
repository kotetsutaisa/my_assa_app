// lib/providers/office/office_employees_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/models/office/employee_with_contract_summary_model.dart';

final officeEmployeesProvider = StateNotifierProvider<
    OfficeEmployeesNotifier,
    AsyncValue<List<EmployeeWithContractSummary>>>(
  (ref) => OfficeEmployeesNotifier(ref),
);

class OfficeEmployeesNotifier extends StateNotifier<
    AsyncValue<List<EmployeeWithContractSummary>>> {
  OfficeEmployeesNotifier(this.ref) : super(const AsyncLoading()) {
    fetch();
  }
  final Ref ref;

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final Dio dio = ref.read(dioProvider);
      final list = await fetchOfficeEmployees(dio);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();

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

    final updated = current.toList();
    final old = updated[idx];
    updated[idx] = old.copyWith(
      mainRateLabel: mainRateLabel ?? old.mainRateLabel,
      updatedAt: updatedAt ?? old.updatedAt,
    );
    state = AsyncValue.data(updated);
  }
}