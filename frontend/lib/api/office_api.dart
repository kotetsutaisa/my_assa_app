// lib/api/office_api.dart
import 'package:dio/dio.dart';
import 'package:frontend/models/office/employee_detail_summary_model.dart';
import 'package:frontend/models/office/employee_with_contract_summary_model.dart';
import 'package:frontend/models/office/payroll_policy_model.dart';
import 'package:frontend/models/office/wage_contract_model.dart';

Future<PayrollPolicyModel> fetchPayrollPolicy(Dio dio) async {
  final res = await dio.get('office/payroll/policy/');
  return PayrollPolicyModel.fromJson(res.data as Map<String, dynamic>);
}

Future<PayrollPolicyModel> updatePayrollPolicy(Dio dio, PayrollPolicyModel model) async {
  final res = await dio.put('office/payroll/policy/', data: model.toJson());
  return PayrollPolicyModel.fromJson(res.data as Map<String, dynamic>);
}

Future<List<WageContractModel>> fetchWageContracts(Dio dio) async {
  final res = await dio.get('office/payroll/contracts/');
  final list = (res.data as List).cast<Map<String, dynamic>>();
  return list.map(WageContractModel.fromJson).toList();
}

Future<WageContractModel> createWageContract(Dio dio, WageContractModel model) async {
  final res = await dio.post('office/payroll/contracts/', data: model.toCreateJson());
  return WageContractModel.fromJson(res.data as Map<String, dynamic>);
}

Future<WageContractModel> patchWageContract(Dio dio, int id, Map<String, dynamic> patch) async {
  final res = await dio.patch('office/payroll/contracts/$id/', data: patch);
  return WageContractModel.fromJson(res.data as Map<String, dynamic>);
}


// ユーザー一覧と最低限の給料データを返すAPI
Future<List<EmployeeWithContractSummary>> fetchOfficeEmployees(
  Dio dio, {
  String? q,                 // 追加: 検索
  String ordering = '-updated_at', // 追加: 並び替え（APIと同じキー）
  int? page,                 // 任意: サーバ側でページングする場合
  int? pageSize,             // 任意
}) async {
  final qp = <String, dynamic>{};
  if (q != null && q.trim().isNotEmpty) qp['q'] = q.trim();
  if (ordering.isNotEmpty) qp['ordering'] = ordering;
  if (page != null) qp['page'] = page;
  if (pageSize != null) qp['page_size'] = pageSize;

  final res = await dio.get('office/employees/', queryParameters: qp);
  final data = res.data as List<dynamic>;
  return data
      .map((e) => EmployeeWithContractSummary.fromJson(
            e as Map<String, dynamic>,
          ))
      .toList(growable: false);
}



/// 従業員の詳細サマリーを取得
/// GET /api/office/employees/<user_id>/
Future<EmployeeDetailSummary> fetchEmployeeDetailSummary(
  Dio dio, {
  required int userId,
}) async {
  final res = await dio.get('office/employees/$userId/');
  return EmployeeDetailSummary.fromJson(res.data as Map<String, dynamic>);
}

/// 特定ユーザーの契約一覧を取得
/// GET /api/office/payroll/contracts/?user_id=<userId>
/// ※ サーバ側の List エンドポイントに 'user_id' 絞り込みを実装済み
Future<List<WageContractModel>> fetchUserWageContracts(
  Dio dio, {
  required int userId,
}) async {
  final res = await dio.get(
    'office/payroll/contracts/',
    queryParameters: {'user_id': userId},
  );
  final list = (res.data as List).cast<Map<String, dynamic>>();
  return list.map(WageContractModel.fromJson).toList(growable: false);
}

/// 契約を新規作成（特定ユーザー向け）
/// POST /api/office/payroll/contracts/
/// 注意: model.toCreateJson() に 'user_id' が含まれている必要があります。
Future<WageContractModel> createWageContractForUser(
  Dio dio, {
  required WageContractModel model,
}) async {
  // 既存の WageContractModel.toCreateJson() をそのまま使用
  final res = await dio.post('office/payroll/contracts/', data: model.toCreateJson());
  return WageContractModel.fromJson(res.data as Map<String, dynamic>);
}

/// 契約を更新（部分更新）
/// PATCH /api/office/payroll/contracts/<id>/
Future<WageContractModel> patchWageContractById(
  Dio dio, {
  required int id,
  required Map<String, dynamic> patch,
}) async {
  final res = await dio.patch('office/payroll/contracts/$id/', data: patch);
  return WageContractModel.fromJson(res.data as Map<String, dynamic>);
}

/// 契約を削除（サーバ側が DELETE を許可している前提）
/// DELETE /api/office/payroll/contracts/<id>/
/// サーバ側が RetrieveUpdateDestroyAPIView にしていない場合は 405 になります。
Future<void> deleteWageContractById(
  Dio dio, {
  required int id,
}) async {
  await dio.delete('office/payroll/contracts/$id/');
}
