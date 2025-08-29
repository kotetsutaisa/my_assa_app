import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/models/office/employee_detail_summary_model.dart';

/// GET /api/office/employees/<user_id>/
final employeeDetailSummaryProvider =
    FutureProvider.family<EmployeeDetailSummary, int>((ref, userId) async {
  final Dio dio = ref.read(dioProvider);
  return fetchEmployeeDetailSummary(dio, userId: userId);
});
