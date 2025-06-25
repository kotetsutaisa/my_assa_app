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

  final response = await dio.post(
    'schedule/my-monthly/',
    data: {
      'site': selectedSite.id,
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
