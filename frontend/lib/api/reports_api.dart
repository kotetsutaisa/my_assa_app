// lib/api/reports_api.dart
import 'package:dio/dio.dart';
import 'package:frontend/models/reports/team_report_model.dart';

/// 個人下書き生成 API の戻り値（必要最低限）
class GeneratePersonalResult {
  final String date;          // "YYYY-MM-DD"
  final String teamId;        // UUID string
  final int countEntries;     // 生成した明細件数
  final List<GeneratedPair> reports; // user_id と report_id のペア

  GeneratePersonalResult({
    required this.date,
    required this.teamId,
    required this.countEntries,
    required this.reports,
  });

  factory GeneratePersonalResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> arr = (json['reports'] as List<dynamic>? ?? []);
    return GeneratePersonalResult(
      date: json['date'] as String,
      teamId: json['team_id'] as String,
      countEntries: (json['count_entries'] as num?)?.toInt() ?? 0,
      reports: arr.map((e) => GeneratedPair.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class GeneratedPair {
  final int userId;
  final String reportId;
  GeneratedPair({required this.userId, required this.reportId});

  factory GeneratedPair.fromJson(Map<String, dynamic> json) {
    return GeneratedPair(
      userId  : (json['user_id'] as num).toInt(),
      reportId: json['report_id'] as String,
    );
  }
}

/// ------------------------------
/// Team Reports
/// ------------------------------

/// 一覧取得
Future<List<TeamReportModel>> fetchTeamReports(
  Dio dio, {
  DateTime? start,
  DateTime? end,
  String? teamId,
  int? memberId,
}) async {
  String? d(DateTime? dt) => dt?.toIso8601String().split('T').first;

  final res = await dio.get(
    'reports/team/',
    queryParameters: {
      if (start != null) 'start': d(start),
      if (end   != null) 'end'  : d(end),
      if (teamId != null && teamId.isNotEmpty) 'team_id': teamId,
      if (memberId != null) 'member_id': memberId,
    },
  );

  final list = (res.data as List)
      .map((j) => TeamReportModel.fromJson(j as Map<String, dynamic>))
      .toList(growable: false);
  return list;
}

/// 詳細取得
Future<TeamReportModel> fetchTeamReportDetail(Dio dio, String id) async {
  final res = await dio.get('reports/team/$id/');
  return TeamReportModel.fromJson(res.data as Map<String, dynamic>);
}

/// 作成（entries ごと）
Future<TeamReportModel> createTeamReport({
  required Dio dio,
  required TeamReportModel model,
  required String teamId,
}) async {
  final payload = model.toPayload(teamId: teamId, includeEntries: true);
  final res = await dio.post('reports/team/', data: payload);
  return TeamReportModel.fromJson(res.data as Map<String, dynamic>);
}

/// 更新（PATCH・entries を送れば置き換え、送らなければ本体のみ）
Future<TeamReportModel> updateTeamReport({
  required Dio dio,
  required String id,
  required Map<String, dynamic> patch, // model.toPayload(..., includeEntries: false) 等
}) async {
  final res = await dio.patch('reports/team/$id/', data: patch);
  return TeamReportModel.fromJson(res.data as Map<String, dynamic>);
}

/// 削除
Future<void> deleteTeamReport(Dio dio, String id) async {
  await dio.delete('reports/team/$id/');
}

/// 個人下書き生成（Team → Personal）
Future<GeneratePersonalResult> generatePersonalFromTeam({
  required Dio dio,
  required String teamReportId,
  bool replaceExisting = true,
}) async {
  final res = await dio.post(
    'reports/team/generate-personal/',
    data: {
      'team_report_id': teamReportId,
      'replace_existing': replaceExisting,
    },
  );
  return GeneratePersonalResult.fromJson(res.data as Map<String, dynamic>);
}
