// lib/providers/office/payroll_policy_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/models/office/payroll_policy_model.dart';

class PayrollPolicyNotifier extends StateNotifier<AsyncValue<PayrollPolicyModel>> {
  final Ref ref;
  PayrollPolicyNotifier(this.ref) : super(const AsyncLoading()) {
    fetch();
  }
  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final data = await fetchPayrollPolicy(dio);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> save(PayrollPolicyModel m) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final saved = await updatePayrollPolicy(dio, m);
      state = AsyncData(saved);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final payrollPolicyProvider =
    StateNotifierProvider<PayrollPolicyNotifier, AsyncValue<PayrollPolicyModel>>(
  (ref) => PayrollPolicyNotifier(ref),
);
