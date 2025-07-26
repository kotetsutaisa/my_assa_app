import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/api/schedule_api.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/dio_provider.dart';

/// リソース別スケジュール用 Notifier（family）
/// key: resourceId
class ResourceScheduleMapNotifier
    extends StateNotifier<AsyncValue<Map<DateTime, List<ScheduleModel>>>> {
  ResourceScheduleMapNotifier(this.ref, this._resourceId)
      : super(const AsyncValue.loading());

  final Ref ref;
  final String _resourceId;

  DateTime? _lastStart;
  DateTime? _lastEnd;

  // ---------------- 取得 ----------------
  Future<void> fetch(DateTime start, DateTime end) async {
    try {
      _lastStart = start;
      _lastEnd   = end;

      state = const AsyncValue.loading();

      final dio = ref.read(dioProvider);
      final schedules = await fetchResourceMonthlySchedules(
        dio       : dio,
        resourceId: _resourceId,
        start     : start,
        end       : end,
      );

      final map = <DateTime, List<ScheduleModel>>{};
      for (final s in schedules) {
        DateTime cur  = DateUtils.dateOnly(s.startTime.toLocal());
        final    last = DateUtils.dateOnly(s.endTime  .toLocal());
        while (!cur.isAfter(last)) {
          map.putIfAbsent(cur, () => []).add(s);
          cur = cur.add(const Duration(days: 1));
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
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
    WorkCategoryModel? selectedWorkCategory,      // 任意
    List<String>? memberIds,                     // 任意
    bool force = false,
  }) async {
    final dio = ref.read(dioProvider);

    try {
      await createResourceSchedule(
        dio            : dio,
        resourceId     : _resourceId,
        selectedSite   : selectedSite,
        startDate      : selectedStartDate,
        startTime      : startTime,
        endDate        : selectedEndDate,
        endTime        : endTime,
        workCategoryId : selectedWorkCategory?.id,
        memberIds      : memberIds,
        force          : force,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) rethrow; // UI側でダイアログ表示
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
      await deleteResourceScheduleApi(dio, scheduleId);

      // ローカル更新
      final cur  = state.value ?? {};
      final next = <DateTime, List<ScheduleModel>>{};
      cur.forEach((d, list) {
        final filtered = list.where((s) => s.id != scheduleId).toList();
        if (filtered.isNotEmpty) next[d] = filtered;
      });
      state = AsyncValue.data(next);

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
    required DateTime selectedStartDate,
    required DateTime startTime,
    required DateTime selectedEndDate,
    required DateTime endTime,
    WorkCategoryModel? selectedWorkCategory,
    List<String>? memberIds,
  }) async {
    try {
      final dio = ref.read(dioProvider);

      final payload = <String, dynamic>{
        'site_id'   : selectedSite.id,
        'start_time': _combine(selectedStartDate, startTime).toIso8601String(),
        'end_time'  : _combine(selectedEndDate, endTime).toIso8601String(),
        'resource_id': _resourceId,
        // schedule_type は PATCH 時省略可（変更しない）
      };
      if (selectedWorkCategory != null) {
        payload['work_category_id'] = selectedWorkCategory.id;
      }
      if (memberIds != null) {
        payload['member_ids'] = memberIds;
      }

      await updateResourceScheduleApi(
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

  // util
  DateTime _combine(DateTime d, DateTime t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

/// family Provider
final resourceScheduleMapProvider = StateNotifierProvider.family<
    ResourceScheduleMapNotifier,
    AsyncValue<Map<DateTime, List<ScheduleModel>>>,
    String>((ref, resourceId) {
  return ResourceScheduleMapNotifier(ref, resourceId);
});
