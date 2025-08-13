import 'package:frontend/models/reports/report_permissions.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/models/reports/team_summary_model.dart';
import 'package:frontend/models/reports/team_report_entry_model.dart';
import 'package:frontend/models/reports/time_utils.dart';

class TeamReportModel {
  final String id;
  final DateTime date;               // YYYY-MM-DD
  final ReportStatus status;

  final TeamSummaryModel team;
  final String? note;

  final SimpleUserModel createdBy;
  final DateTime createdAt;
  final DateTime? submittedAt;

  final List<TeamReportEntryModel> entries;

  final ReportPermissions permissions;

  const TeamReportModel({
    required this.id,
    required this.date,
    required this.status,
    required this.team,
    required this.createdBy,
    required this.createdAt,
    required this.entries,
    this.note,
    this.submittedAt,
    this.permissions = const ReportPermissions(canViewDetail: false, canDelete: false),
  });

  factory TeamReportModel.fromJson(Map<String, dynamic> json) {
    return TeamReportModel(
      id         : json['id'] as String,
      date       : parseDateOnly(json['date'] as String),
      status     : ReportStatusX.fromApi(json['status'] as String?),
      team       : TeamSummaryModel.fromJson(json['team'] as Map<String, dynamic>),
      note       : json['note'] as String?,
      createdBy  : SimpleUserModel.fromJson(json['created_by'] as Map<String, dynamic>),
      createdAt  : DateTime.parse(json['created_at'] as String).toLocal(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String).toLocal()
          : null,
      entries    : (json['entries'] as List<dynamic>)
          .map((e) => TeamReportEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      permissions: ReportPermissions.fromJson(json['permissions'] as Map<String, dynamic>?),
    );
  }

  /// POST/PUT/PATCH 用（entries を含む）
  /// - `teamId` は作成時・変更時に必要（PATCHでも team 変更を許す場合）
  /// - `entryPayloads` は TeamReportEntryModel#toPayload の結果配列
  Map<String, dynamic> toPayload({
    required String teamId,
    bool includeEntries = true,
    List<Map<String, dynamic>>? entryPayloads,
  }) {
    return {
      'date'   : formatDateOnly(date),
      'status' : status.apiValue,
      'team_id': teamId,
      if (note != null) 'note': note,
      if (includeEntries)
        'entries': entryPayloads ?? entries.map((e) => e.toPayload(
          siteId       : e.site.id!,
          workCategoryId: e.workCategory?.id,
          memberId     : e.member.id, // SimpleUserModel.id が int 想定
        )).toList(),
    };
  }
}
