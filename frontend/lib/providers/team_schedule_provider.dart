import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/schedule_api.dart';          // ← チーム用 API もここに実装した前提
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/dio_provider.dart';

/// チームスケジュール用  StateNotifier
///
/// * Personal 版との差分は **API の呼び出し先とペイロード** だけ  
/// * “予定人員（memberIds）” などチーム特有パラメータは
///   必要に応じてメソッド引数を拡張してください
class TeamScheduleMapNotifier
    extends StateNotifier<AsyncValue<Map<DateTime, List<ScheduleModel>>>> {
  final Ref ref;
  DateTime? _lastStart;
  DateTime? _lastEnd;

  TeamScheduleMapNotifier(this.ref) : super(const AsyncValue.loading());

  // ---------------- 取得 ----------------
  Future<void> fetch(DateTime start, DateTime end) async {
    try {
      _lastStart = start;
      _lastEnd   = end;

      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);

      // 👇 Personal → Team 用 API へ置換
      final schedules = await fetchTeamMonthlySchedules(dio, start, end);

      final map = <DateTime, List<ScheduleModel>>{};
      for (final s in schedules) {
        // 開始日の 00:00, 終了日の 00:00
        DateTime cur  = DateUtils.dateOnly(s.startTime.toLocal());
        final    last = DateUtils.dateOnly(s.endTime  .toLocal());

        while (!cur.isAfter(last)) {
          map.putIfAbsent(cur, () => []).add(s);   // その日の配列に追加
          cur = cur.add(const Duration(days: 1));  // 次の日へ
        }
      }

      state = AsyncValue.data(map);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------- 作成 ----------------
  Future<void> addSchedule({
    required SiteModel selectedSite,
    required WorkCategoryModel selectedWorkCategory,
    required List<String> memberIds,  // 👈 チーム用: 予定人員を追加
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
    bool force = false,
  }) async {
    final dio = ref.read(dioProvider);

    try {
      await createTeamSchedule(
        dio              : dio,
        selectedSite     : selectedSite,
        selectedWorkCategory: selectedWorkCategory,
        memberIds        : memberIds,
        selectedStartDate: selectedStartDate,
        startTime        : startTime,
        selectedEndDate  : selectedEndDate,
        endTime          : endTime,
        force            : force,      // ★
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) rethrow;
      state = AsyncValue.error(e, StackTrace.current);
      return;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return;
    }

    final start = _lastStart ??
        DateTime(selectedStartDate.year, selectedStartDate.month, 1);
    final end   = _lastEnd ??
        DateTime(selectedStartDate.year, selectedStartDate.month + 1, 0);
    await fetch(start, end);
  }

  // ---------------- 削除 ----------------
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final dio = ref.read(dioProvider);
      await deleteTeamScheduleApi(dio, scheduleId);   // 👈 置換

      // ローカルキャッシュを即時更新
      final cur  = state.value ?? {};
      final next = <DateTime, List<ScheduleModel>>{};
      cur.forEach((d, list) {
        final filtered = list.where((s) => s.id != scheduleId).toList();
        if (filtered.isNotEmpty) next[d] = filtered;
      });
      state = AsyncValue.data(next);

      // バックエンドと再同期
      if (_lastStart != null && _lastEnd != null) {
        await fetch(_lastStart!, _lastEnd!);
      }

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ---------------- 更新 ----------------
  Future<void> updateSchedule({
    required String id,
    required SiteModel selectedSite,
    required WorkCategoryModel selectedWorkCategory,
    required List<String> memberIds,   // 👈 追加
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
  }) async {
    try {
      final dio = ref.read(dioProvider);

      final payload = {
        'site'            : selectedSite.id,
        'work_category_id': selectedWorkCategory.id,
        'member_ids'      : memberIds,  // 👈 チーム用
        'start_time'      : _combine(selectedStartDate, startTime).toIso8601String(),
        'end_time'        : _combine(selectedEndDate, endTime).toIso8601String(),
      };

      await updateTeamScheduleApi(     // 👈 置換
        dio       : dio,
        scheduleId: id,
        payload   : payload,
      );

      final start = _lastStart ??
          DateTime(selectedStartDate.year, selectedStartDate.month, 1);
      final end   = _lastEnd ??
          DateTime(selectedStartDate.year, selectedStartDate.month + 1, 0);
      await fetch(start, end);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ---------------- util ----------------
  DateTime _combine(DateTime d, DateTime t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

/// Provider 登録
final teamScheduleMapProvider = StateNotifierProvider<
    TeamScheduleMapNotifier,
    AsyncValue<Map<DateTime, List<ScheduleModel>>>>(
  (ref) => TeamScheduleMapNotifier(ref),
);
