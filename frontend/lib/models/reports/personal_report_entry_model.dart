import 'package:flutter/material.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'time_utils.dart';

class PersonalReportEntryModel {
  final String id;
  final SiteModel site;
  final WorkCategoryModel? workCategory;

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  final String? note;

  /// サーバー計算値（read-only）
  final int? workMinutes;

  /// サーバー管理フラグ（read-only）
  final bool changedFromSource;

  const PersonalReportEntryModel({
    required this.id,
    required this.site,
    required this.startTime,
    required this.endTime,
    this.workCategory,
    this.note,
    this.workMinutes,
    this.changedFromSource = false,
  });

  factory PersonalReportEntryModel.fromJson(Map<String, dynamic> json) {
    return PersonalReportEntryModel(
      id            : json['id'] as String,
      site          : SiteModel.fromJson(json['site'] as Map<String, dynamic>),
      workCategory  : json['work_category'] != null
          ? WorkCategoryModel.fromJson(json['work_category'] as Map<String, dynamic>)
          : null,
      startTime     : parseTimeOfDay(json['start_time'] as String),
      endTime       : parseTimeOfDay(json['end_time']   as String),
      note          : json['note'] as String?,
      workMinutes   : json['work_minutes'] as int?,
      changedFromSource: json['changed_from_source'] as bool? ?? false,
    );
  }

  /// POST/PATCH 用ペイロード
  Map<String, dynamic> toPayload() {
    return {
      'site_id'         : site.id,                          // SiteModel: id は UUID 文字列想定
      'work_category_id': workCategory?.id,                 // WorkCategoryModel: id は int 想定
      'start_time'      : formatTimeOfDay(startTime),
      'end_time'        : formatTimeOfDay(endTime),
      if (note != null) 'note': note,
    };
  }

  PersonalReportEntryModel copyWith({
    SiteModel? site,
    WorkCategoryModel? workCategory,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? note,
    int? workMinutes,
    bool? changedFromSource,
  }) {
    return PersonalReportEntryModel(
      id: id,
      site: site ?? this.site,
      workCategory: workCategory ?? this.workCategory,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      workMinutes: workMinutes ?? this.workMinutes,
      changedFromSource: changedFromSource ?? this.changedFromSource,
    );
  }
}
