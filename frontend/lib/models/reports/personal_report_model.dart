import 'package:frontend/models/reports/report_permissions.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/reports/report_status.dart';
import 'package:frontend/models/reports/personal_report_entry_model.dart';
import 'package:frontend/models/reports/time_utils.dart';

class PersonalReportModel {
  final String id;
  final DateTime date;                 // YYYY-MM-DD
  final ReportStatus status;

  final SimpleUserModel user;
  final String? note;

  final DateTime? submittedAt;
  final DateTime createdAt;

  final List<PersonalReportEntryModel> entries;

  final ReportPermissions permissions;
  final bool hasDiffFromSource;

  const PersonalReportModel({
    required this.id,
    required this.date,
    required this.status,
    required this.user,
    required this.entries,
    required this.createdAt,
    this.note,
    this.submittedAt,
    this.permissions = const ReportPermissions(canViewDetail: false, canDelete: false),
    this.hasDiffFromSource = false,
  });

  factory PersonalReportModel.fromJson(Map<String, dynamic> json) {
    return PersonalReportModel(
      id         : json['id'] as String,
      date       : parseDateOnly(json['date'] as String),
      status     : ReportStatusX.fromApi(json['status'] as String?),
      user       : SimpleUserModel.fromJson(json['user'] as Map<String, dynamic>),
      note       : json['note'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String).toLocal()
          : null,
      createdAt  : DateTime.parse(json['created_at'] as String).toLocal(),
      entries    : (json['entries'] as List<dynamic>)
          .map((e) => PersonalReportEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      permissions: ReportPermissions.fromJson(json['permissions'] as Map<String, dynamic>?),
      hasDiffFromSource: json['has_diff_from_source'] as bool? ?? false,
    );
  }

  /// POST/PUT/PATCH 用（entries を含む作成・更新）
  /// - `userId` は代理作成時のみ指定（通常はサーバ側で request.user を使用）
  Map<String, dynamic> toPayload({int? userId, bool includeEntries = true}) {
    return {
      'date'  : formatDateOnly(date),
      'status': status.apiValue,
      if (userId != null) 'user_id': userId,
      if (note != null) 'note': note,
      if (includeEntries)
        'entries': entries.map((e) => e.toPayload()).toList(),
    };
  }

  PersonalReportModel copyWith({
    DateTime? date,
    ReportStatus? status,
    String? note,
    List<PersonalReportEntryModel>? entries,
    DateTime? submittedAt,
    ReportPermissions? permissions,
    bool? hasDiffFromSource,
  }) {
    return PersonalReportModel(
      id: id,
      date: date ?? this.date,
      status: status ?? this.status,
      user: user,
      createdAt: createdAt,
      note: note ?? this.note,
      submittedAt: submittedAt ?? this.submittedAt,
      entries: entries ?? this.entries,
      permissions: permissions ?? this.permissions,
      hasDiffFromSource: hasDiffFromSource ?? this.hasDiffFromSource,
    );
  }
}
