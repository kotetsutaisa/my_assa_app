import 'package:dio/dio.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';

// スケジュール取得
Future<List<ScheduleModel>> fetchMyMonthlySchedules(
  Dio dio,
  DateTime start,
  DateTime end
) async {
  final response = await dio.get(
    'schedule/my-monthly/',
    queryParameters: {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    },
  );

  return (response.data as List)
    .map((json) => ScheduleModel.fromJson(json))
    .toList();
}

// スケジュール作成
Future<ScheduleModel> createSchedule({
  required Dio dio,
  required SiteModel selectedSite,
  required WorkCategoryModel selectedWorkCategory,
  required DateTime selectedStartDate,
  required DateTime startTime,
  required DateTime selectedEndDate,
  required DateTime endTime,
  bool force = false,
}) async {
  // 開始日
  final DateTime startDateTime = DateTime(
    selectedStartDate.year,
    selectedStartDate.month,
    selectedStartDate.day,
    startTime.hour,
    startTime.minute,
  );

  // 終了日
  final DateTime endDateTime = DateTime(
    selectedEndDate.year,
    selectedEndDate.month,
    selectedEndDate.day,
    endTime.hour,
    endTime.minute,
  );

  if (!endDateTime.isAfter(startDateTime)) {
    // UI 側で SnackBar を出したい場合は catch して message を表示
    throw Exception('終了日時は開始日時より後にしてください');
  }

  final qs = force ? '?force=true' : '';

  final response = await dio.post(
    'schedule/my-monthly/$qs',
    data: {
      'site_id': selectedSite.id,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime.toIso8601String(),
      'schedule_type': 'personal',
      'work_category_id': selectedWorkCategory.id,
    },
  );

  return ScheduleModel.fromJson(response.data as Map<String, dynamic>);
}


// スケジュール削除
Future<void> deleteScheduleApi(Dio dio, String scheduleId) async {
  await dio.delete('schedule/$scheduleId/');
}

// スケジュール編集
Future<ScheduleModel> updateScheduleApi({
  required Dio dio,
  required String scheduleId,
  required Map<String, dynamic> payload,
}) async {
  final res = await dio.patch('schedule/$scheduleId/', data: payload);
  return ScheduleModel.fromJson(res.data);
}


// 作業内容一覧取得
Future<List<WorkCategoryModel>> fetchWorkCategories(Dio dio) async {
  final response = await dio.get('schedule/work-categories/');
  return (response.data as List)
      .map((json) => WorkCategoryModel.fromJson(json))
      .toList();
}

// 作業内容作成
Future<WorkCategoryModel> createWorkCategory(Dio dio, String name) async {
  final response = await dio.post(
    'schedule/work-categories/',
    data: {'name': name},
  );
  return WorkCategoryModel.fromJson(response.data);
}

// 作業内容削除
Future<void> deleteWorkCategory(Dio dio, int id) async {
  await dio.delete('schedule/work-categories/$id/');
}


/* ------------------------------------------------------------------ */
/*                          ▼ チームスケジュール ▼                    */
/* ------------------------------------------------------------------ */

// 月間取得
Future<List<ScheduleModel>> fetchTeamMonthlySchedules(
  Dio dio,
  DateTime start,
  DateTime end,
) async {
  final res = await dio.get(
    'schedule/team-monthly/',
    queryParameters: {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    },
  );

  return (res.data as List)
      .map((json) => ScheduleModel.fromJson(json))
      .toList();
}


// 作成
Future<ScheduleModel> createTeamSchedule({
  required Dio dio,
  required SiteModel selectedSite,
  required WorkCategoryModel selectedWorkCategory,
  required List<String> memberIds,          // ★ 予定人員
  required DateTime selectedStartDate,
  required DateTime startTime,
  required DateTime selectedEndDate,
  required DateTime endTime,
  List<String>? teamIds,
  bool force = false,
}) async {
  // 開始日時
  final startDateTime = DateTime(
    selectedStartDate.year,
    selectedStartDate.month,
    selectedStartDate.day,
    startTime.hour,
    startTime.minute,
  );

  // 終了日時
  final endDateTime = DateTime(
    selectedEndDate.year,
    selectedEndDate.month,
    selectedEndDate.day,
    endTime.hour,
    endTime.minute,
  );

  if (!endDateTime.isAfter(startDateTime)) {
    throw Exception('終了日時は開始日時より後にしてください');
  }

  final qs = force ? '?force=true' : '';

  final payload = <String, dynamic>{
    'site_id'         : selectedSite.id,
    'start_time'      : startDateTime.toIso8601String(),
    'end_time'        : endDateTime.toIso8601String(),
    'schedule_type'   : 'team',                // （バックエンドで固定なら省略可）
    'work_category_id': selectedWorkCategory.id,
    'member_ids'      : memberIds,
  };

  if (teamIds != null && teamIds.isNotEmpty) {
    payload['team_ids'] = teamIds;
  }

  final res = await dio.post(
    'schedule/team-monthly/$qs',
    data: payload,
  );

  return ScheduleModel.fromJson(res.data as Map<String, dynamic>);
}


// 削除（エンドポイントは個人と共通） 
Future<void> deleteTeamScheduleApi(Dio dio, String scheduleId) async {
  await dio.delete('schedule/$scheduleId/');
}


// 更新
Future<ScheduleModel> updateTeamScheduleApi({
  required Dio dio,
  required String scheduleId,
  required Map<String, dynamic> payload,     // payload 内に member_ids を含める
}) async {
  final res = await dio.patch('schedule/$scheduleId/', data: payload);
  return ScheduleModel.fromJson(res.data);
}



/* ------------------------------------------------------------------ */
/*                          ▼ リソーススケジュール ▼                    */
/* ------------------------------------------------------------------ */

/// 月間取得（リソース別）
/// GET /api/schedule/resource-monthly/?resource_id=xxx&start=...&end=...
Future<List<ScheduleModel>> fetchResourceMonthlySchedules({
  required Dio dio,
  required String resourceId,
  required DateTime start,
  required DateTime end,
}) async {
  final res = await dio.get(
    'schedule/resource-monthly/',
    queryParameters: {
      'resource_id': resourceId,
      'start'      : start.toIso8601String(),
      'end'        : end.toIso8601String(),
    },
  );

  return (res.data as List)
      .map((json) => ScheduleModel.fromJson(json))
      .toList();
}

/// 作成
/// POST /api/schedule/resource-monthly/  (?force=true 対応)
Future<ScheduleModel> createResourceSchedule({
  required Dio dio,
  required String resourceId,
  required SiteModel selectedSite,
  required DateTime startDate,
  required DateTime startTime,
  required DateTime endDate,
  required DateTime endTime,
  int? workCategoryId,        // 任意
  List<String>? memberIds,       // 任意
  bool force = false,
}) async {
  final startDT = DateTime(
    startDate.year, startDate.month, startDate.day,
    startTime.hour, startTime.minute,
  );
  final endDT = DateTime(
    endDate.year, endDate.month, endDate.day,
    endTime.hour, endTime.minute,
  );

  if (!endDT.isAfter(startDT)) {
    throw Exception('終了日時は開始日時より後にしてください');
  }

  final payload = <String, dynamic>{
    'resource_id'    : resourceId,
    'site_id'        : selectedSite.id,
    'start_time'     : startDT.toIso8601String(),
    'end_time'       : endDT.toIso8601String(),
    'schedule_type'  : 'resource',   // バックエンドで固定なら省略可
  };
  if (workCategoryId != null) payload['work_category_id'] = workCategoryId;
  if (memberIds != null && memberIds.isNotEmpty) {
    payload['member_ids'] = memberIds;
  }

  final qs = force ? '?force=true' : '';
  final res = await dio.post('schedule/resource-monthly/$qs', data: payload);
  return ScheduleModel.fromJson(res.data as Map<String, dynamic>);
}

/// 更新
/// PATCH /api/schedule/<id>/
Future<ScheduleModel> updateResourceScheduleApi({
  required Dio dio,
  required String scheduleId,
  required Map<String, dynamic> payload,
}) async {
  final res = await dio.patch('schedule/$scheduleId/', data: payload);
  return ScheduleModel.fromJson(res.data);
}

/// 削除（共通エンドポイント）
/// DELETE /api/schedule/<id>/
Future<void> deleteResourceScheduleApi(Dio dio, String scheduleId) async {
  await dio.delete('schedule/$scheduleId/');
}
