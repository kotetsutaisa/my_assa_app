import 'package:flutter/material.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'time_utils.dart';

class TeamReportEntryModel {
  final String id;
  final SiteModel site;
  final WorkCategoryModel? workCategory;
  final SimpleUserModel member;

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  final String? note;

  const TeamReportEntryModel({
    required this.id,
    required this.site,
    required this.member,
    required this.startTime,
    required this.endTime,
    this.workCategory,
    this.note,
  });

  factory TeamReportEntryModel.fromJson(Map<String, dynamic> json) {
    return TeamReportEntryModel(
      id           : json['id'] as String,
      site         : SiteModel.fromJson(json['site'] as Map<String, dynamic>),
      workCategory : json['work_category'] != null
          ? WorkCategoryModel.fromJson(json['work_category'] as Map<String, dynamic>)
          : null,
      member       : SimpleUserModel.fromJson(json['member'] as Map<String, dynamic>),
      startTime    : parseTimeOfDay(json['start_time'] as String),
      endTime      : parseTimeOfDay(json['end_time']   as String),
      note         : json['note'] as String?,
    );
  }

  /// POST/PATCH 用
  /// - site_id / work_category_id / member_id を送る必要がある
  Map<String, dynamic> toPayload({
    required String siteId,    // site.id が UUID 文字列
    int? workCategoryId,       // null 許容
    required int memberId,     // SimpleUserModel.id は int 想定
  }) {
    return {
      'site_id'         : siteId,
      'work_category_id': workCategoryId,
      'member_id'       : memberId,
      'start_time'      : formatTimeOfDay(startTime),
      'end_time'        : formatTimeOfDay(endTime),
      if (note != null) 'note': note,
    };
  }
}
