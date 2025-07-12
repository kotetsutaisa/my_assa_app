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
  required Future<void> Function({bool force}) request,   // ← 成功時/再試行時に呼ぶ
}) async {
  try {
    await request(force: false);
    return;                           // 正常終了
  } on DioException catch (e) {
    if (e.response?.statusCode != 409) rethrow;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title  : const Text('予定が重複しています'),
        content: const Text('既存の予定を削除して登録しますか？'),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(dialogCtx, false),
          ),
          TextButton(
            child: const Text('上書き'),
            onPressed: () => Navigator.pop(dialogCtx, true),
          ),
        ],
      ),
    );

    if (ok == true) {
      await request(force: true);     // ← 再実行 (force= true)
    }
  }
}
