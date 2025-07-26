// lib/utils/schedule_conflict_helper.dart
//
// 個人スケジュール向け: 重複チェック → ダイアログ → force 再送信
// ──────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/my_personal_schedule_provider.dart';

/// UI から渡すパラメータを 1 つに束ねるだけの DTO
class AddScheduleParams {
  final SiteModel selectedSite;
  final WorkCategoryModel selectedWorkCategory;
  final DateTime selectedStartDate;
  final DateTime startTime;
  final DateTime selectedEndDate;
  final DateTime endTime;
  const AddScheduleParams({
    required this.selectedSite,
    required this.selectedWorkCategory,
    required this.selectedStartDate,
    required this.startTime,
    required this.selectedEndDate,
    required this.endTime,
  });
}

/// 409（時間帯重複）時に確認ダイアログを挟んで再実行する共通関数
Future<void> addScheduleWithConfirm(
  BuildContext context, {
  required MyPersonalScheduleMapNotifier notifier,
  required AddScheduleParams params,
}) async {
  // ① まず普通に作成を試みる
  try {
    await notifier.addSchedule(
      selectedSite        : params.selectedSite,
      selectedWorkCategory: params.selectedWorkCategory,
      selectedStartDate   : params.selectedStartDate,
      startTime           : params.startTime,
      selectedEndDate     : params.selectedEndDate,
      endTime             : params.endTime,
      force               : false,
    );
    return;                         // ← 成功ならここで終了
  } on DioException catch (e) {
    // ② 409(CONFLICT) 以外はそのまま投げる
    if (e.response?.statusCode != 409) rethrow;
  }

  // ③ 409 だった場合だけダイアログを表示
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title  : const Text('予定が重複しています'),
      content: const Text('既存の予定を置き換えて登録しますか？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('キャンセル')),
        TextButton(onPressed: () => Navigator.pop(dialogCtx, true ), child: const Text('登録')),
      ],
    ),
  );

  if (confirm != true) return;      // キャンセルなら何もしない

  // ④ force=true で再送信（バックエンドが既存予定を削除して上書き）
  await notifier.addSchedule(
    selectedSite        : params.selectedSite,
    selectedWorkCategory: params.selectedWorkCategory,
    selectedStartDate   : params.selectedStartDate,
    startTime           : params.startTime,
    selectedEndDate     : params.selectedEndDate,
    endTime             : params.endTime,
    force               : true,
  );
}
