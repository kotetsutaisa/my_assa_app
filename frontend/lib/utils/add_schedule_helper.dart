// add_schedule_helper.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// 汎用パラメータ
class AddScheduleParams {
  final DateTime startDate, endDate;
  final DateTime startTime, endTime;
  final String siteId;
  final String workCategoryId;
  final List<String> memberIds;       // ← チームでは必須、個人は空配列で OK
  const AddScheduleParams({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.siteId,
    required this.workCategoryId,
    this.memberIds = const [],
  });
}

/// “409→確認→force=true” 共通処理
Future<void> addScheduleWithConfirm({
  required BuildContext context,
  required Future<void> Function({bool force}) request,
  String? conflictTitle,     // ← 追加
  String? conflictMessage,   // ← 追加
  String okLabel = '上書き',
  String cancelLabel = 'キャンセル',
}) async {
  try {
    await request(force: false);
    return;
  } on DioException catch (e) {
    if (e.response?.statusCode != 409) rethrow;

    // バックエンドの detail で出し分ける（resource_overlap / member_overlap / overlap など）
    final detail = e.response?.data is Map
        ? (e.response?.data['detail'] as String?)
        : null;

    // デフォルト文言
    String title   = conflictTitle  ?? '予定が重複しています';
    String message = conflictMessage ?? '既存の予定を削除して登録しますか？';

    if (detail == 'resource_overlap') {
      title   = conflictTitle  ?? 'リソース予約が重複しています';
      message = conflictMessage ?? '既存の予約を削除して登録しますか？';
    } else if (detail == 'member_overlap') {
      title   = conflictTitle  ?? 'メンバーの予定が重複しています';
      message = conflictMessage ?? '重複しているメンバーを外して登録しますか？';
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title  : Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(cancelLabel),
            onPressed: () => Navigator.pop(dialogCtx, false),
          ),
          TextButton(
            child: Text(okLabel),
            onPressed: () => Navigator.pop(dialogCtx, true),
          ),
        ],
      ),
    );

    if (ok == true) {
      await request(force: true);
    }
  }
}
