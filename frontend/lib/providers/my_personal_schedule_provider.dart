import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/schedule_api.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/dio_provider.dart';

class MyPersonalScheduleMapNotifier
    extends StateNotifier<AsyncValue<Map<DateTime, List<ScheduleModel>>>> {
  final Ref ref;
  DateTime? _lastStart;
  DateTime? _lastEnd;

  MyPersonalScheduleMapNotifier(this.ref)
      : super(const AsyncValue.loading());

  // スケジュール取得
  Future<void> fetch(DateTime start, DateTime end) async {
    try {
      _lastStart = start;
      _lastEnd   = end;

      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final schedules = await fetchMyMonthlySchedules(dio, start, end);

      final map = <DateTime, List<ScheduleModel>>{};

      for (final s in schedules) {
        // 1️⃣ 受け取った UTC → ローカルへ
        final localStart = s.startTime.toLocal();

        // 2️⃣ 日付だけを 00:00 固定で取り出し
        final dateKey = DateUtils.dateOnly(localStart);

        map.putIfAbsent(dateKey, () => []).add(s);
      }

      state = AsyncValue.data(map);
    } catch (e, st) {
      print('❌ エラー: $e');
      state = AsyncValue.error(e, st);
    }
  }

  // スケジュール作成
  Future<void> addSchedule({
    required SiteModel selectedSite,
    required WorkCategoryModel selectedWorkCategory,
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await createSchedule(
        dio: dio,
        selectedSite: selectedSite,
        selectedWorkCategory:
        selectedWorkCategory,
        selectedStartDate:
        selectedStartDate,
        startTime: startTime,
        selectedEndDate: selectedEndDate,
        endTime: endTime
      );

      // TODO: 将来チームモード追加時に通信量を削減する。
      //       → 月またぎや差分取得の最適化を検討する。
      // ① 前回 fetch 済みの範囲があればそれを
      // ② 初回なら「追加した予定を含む月」丸ごと
      final start = _lastStart ??
          DateTime(selectedStartDate.year, selectedStartDate.month, 1);
      final end   = _lastEnd ??
          DateTime(selectedStartDate.year, selectedStartDate.month + 1, 0);

      await fetch(start, end);// ← ここで整合を取る
    } catch (e, st) {
      print('❌ エラー: $e');
      state = AsyncValue.error(e, st);
    }
  }

  // スケジュール削除
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final dio = ref.read(dioProvider);

      await deleteScheduleApi(dio, scheduleId);

      final cur = state.value ?? {};
      final next = <DateTime, List<ScheduleModel>>{};

      cur.forEach((date, list) {
        final filtered = list.where((s) => s.id != scheduleId).toList();
        if (filtered.isNotEmpty) next[date] = filtered;
      });

      state = AsyncValue.data(next);

      if (_lastStart != null && _lastEnd != null) {
        await fetch(_lastStart!, _lastEnd!);
      }

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  // スケジュール編集
  Future<void> updateSchedule({
    required String id,
    required SiteModel selectedSite,
    required WorkCategoryModel selectedWorkCategory,
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
  }) async {
    try {
      final dio = ref.read(dioProvider);

      Map<String, dynamic> payload = {
        'site'            : selectedSite.id,
        'work_category_id': selectedWorkCategory.id,
        'start_time'      : _combine(selectedStartDate, startTime).toIso8601String(),
        'end_time'        : _combine(selectedEndDate, endTime).toIso8601String(),
      };

      await updateScheduleApi(
        dio: dio,
        scheduleId: id,
        payload: payload
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

  // 日付と時間の合併
  DateTime _combine(DateTime d, DateTime t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

final myPersonalScheduleMapProvider = StateNotifierProvider<
    MyPersonalScheduleMapNotifier,
    AsyncValue<Map<DateTime, List<ScheduleModel>>>>(
  (ref) => MyPersonalScheduleMapNotifier(ref),
);
