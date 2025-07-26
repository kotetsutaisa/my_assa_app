import 'package:frontend/models/resource_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/team_info_model.dart';
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

  /// ★ 追加: 関連するチーム（team スケジュールのみ値あり / personal は空）
  final List<TeamInfo> teams;

  final ResourceModel? resource;

  ScheduleModel({
    required this.id,
    required this.siteName,
    required this.site,
    required this.startTime,
    required this.endTime,
    required this.scheduleType,
    this.workCategory,
    required this.members,
    this.teams = const [],          // ← 追加（デフォルト空）
    this.resource,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    // 既存部分はそのまま
    final workCatJson = json['work_category'];
    final membersJson = (json['members'] as List<dynamic>?) ?? [];
    final teamsJson   = (json['teams']   as List<dynamic>?) ?? [];
    final resJson     = json['resource'];

    ResourceModel? resModel;
    if (resJson is Map<String, dynamic>) {
      // サーバがネストを返す場合
      resModel = ResourceModel.fromJson(resJson);
    } else {
      // StringRelatedField のまま等、Map でないなら null のまま（必要なら拡張）
      resModel = null;
    }

    return ScheduleModel(
      id          : json['id'] as String,
      siteName    : json['site_name'] ?? '',
      site        : SiteModel.fromJson(json['site']),
      startTime   : DateTime.parse(json['start_time']).toLocal(),
      endTime     : DateTime.parse(json['end_time']).toLocal(),
      scheduleType: json['schedule_type'] as String,
      workCategory: workCatJson != null
          ? WorkCategoryModel.fromJson(workCatJson)
          : null,
      members: membersJson
          .map((m) => SimpleUserModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      teams: teamsJson.map((t) {
        final Map<String, dynamic> m = t as Map<String, dynamic>;
        return TeamInfo(
          id  : m['id']   as String,
            // Serializer 側が name しか返していない現状を想定
          name: m['name'] as String,
            // role がまだ無い場合は 'member' をデフォルトで補完
          role: (m['role'] ?? 'member') as String,
        );
      }).toList(),
      resource: resModel,
    );
  }
}