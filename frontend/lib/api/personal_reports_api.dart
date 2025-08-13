// lib/api/personal_reports_api.dart
import 'package:dio/dio.dart';
import 'package:frontend/models/reports/personal_report_model.dart';

/// 一覧取得
///
/// GET /api/reports/personal/?start=YYYY-MM-DD&end=YYYY-MM-DD&user_id=<id|me>
Future<List<PersonalReportModel>> fetchPersonalReports(
  Dio dio, {
  DateTime? start,
  DateTime? end,
  String? userIdParam, // 'me' または ユーザーID(文字列化)
}) async {
  String? d(DateTime? dt) => dt?.toIso8601String().split('T').first;

  final res = await dio.get(
    'reports/personal/',
    queryParameters: {
      if (start != null) 'start': d(start),
      if (end   != null) 'end'  : d(end),
      if (userIdParam != null && userIdParam.isNotEmpty) 'user_id': userIdParam,
    },
  );

  return (res.data as List)
      .map((j) => PersonalReportModel.fromJson(j as Map<String, dynamic>))
      .toList(growable: false);
}

/// 詳細取得
///
/// GET /api/reports/personal/<uuid>/
Future<PersonalReportModel> fetchPersonalReportDetail(Dio dio, String id) async {
  final res = await dio.get('reports/personal/$id/');
  return PersonalReportModel.fromJson(res.data as Map<String, dynamic>);
}

DateTime _pickSingleDate(DateTime? start, DateTime? end) {
  final base = start ?? end ?? DateTime.now();
  return DateTime(base.year, base.month, base.day); // 日付のみ
}

String _dateOnly(DateTime dt) => dt.toIso8601String().split('T').first;

/// ログインユーザー（me）の「指定日の個人日報」を 0 or 1 件で返す。
/// - start/end は null 可。null のときは今日を送る
/// - 両方指定された場合は start の日付を採用（=1日分想定）
Future<PersonalReportModel?> fetchMyPersonalReportForDay(
  Dio dio, {
  DateTime? start,
  DateTime? end,
}) async {
  final d = _dateOnly(_pickSingleDate(start, end));

  final res = await dio.get(
    'reports/personal/',
    queryParameters: {
      'start': d,
      'end'  : d,
      'user_id': 'me',
    },
  );

  final list = (res.data as List)
      .map((j) => PersonalReportModel.fromJson(j as Map<String, dynamic>))
      .toList(growable: false);

  return list.isNotEmpty ? list.first : null;
}

/// 作成（entries を含む）
///
/// POST /api/reports/personal/
/// - `model.toPayload(userId: ...)` がある想定。無い場合は Map を直接渡してください。
Future<PersonalReportModel> createPersonalReport({
  required Dio dio,
  required PersonalReportModel model,
  int? userId, // 代理作成する場合のみセット。未指定なら request.user
}) async {
  final payload = model.toPayload(userId: userId);
  final res = await dio.post('reports/personal/', data: payload);
  return PersonalReportModel.fromJson(res.data as Map<String, dynamic>);
}

/// 更新（部分更新）
///
/// PATCH /api/reports/personal/<uuid>/
/// - entries を送れば “全入れ替え”
/// - entries を送らなければ本体のみ
Future<PersonalReportModel> updatePersonalReport({
  required Dio dio,
  required String id,
  required Map<String, dynamic> patch,
}) async {
  final res = await dio.patch('reports/personal/$id/', data: patch);
  return PersonalReportModel.fromJson(res.data as Map<String, dynamic>);
}

/// 削除
///
/// DELETE /api/reports/personal/<uuid>/
Future<void> deletePersonalReport(Dio dio, String id) async {
  await dio.delete('reports/personal/$id/');
}
