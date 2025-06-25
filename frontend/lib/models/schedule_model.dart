import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';

class ScheduleModel {
  final String id;
  final String siteName;
  final SiteModel site;
  final DateTime startTime;
  final DateTime endTime;
  final String scheduleType;
  final WorkCategoryModel? workCategory;
  final List<SimpleUserModel> members;

  ScheduleModel({
    required this.id,
    required this.siteName,
    required this.site,
    required this.startTime,
    required this.endTime,
    required this.scheduleType,
    required this.workCategory,
    required this.members,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      siteName: json['site_name'] ?? '',
      site: SiteModel.fromJson(json['site']),
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      scheduleType: json['schedule_type'],
      workCategory: json['work_category'] != null
          ? WorkCategoryModel.fromJson(json['work_category'])
          : null,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => SimpleUserModel.fromJson(m))
              .toList() ??
          [],
    );
  }
}