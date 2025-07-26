import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/providers/resource_schedule_provider.dart';

/// ------------------------------------------------------------
/// ① 追加: 選択中の日付（リソース用）
/// ------------------------------------------------------------
final selectedResourceDateProvider =
    StateProvider<DateTime>((_) => DateTime.now());

/// ------------------------------------------------------------
/// ② 追加: family Provider（resourceId ごとに状態を分離）
///     ※ すでに実装済みならスキップしてOK
/// ------------------------------------------------------------
final resourceScheduleMapProvider = StateNotifierProvider.family<
    ResourceScheduleMapNotifier,
    AsyncValue<Map<DateTime, List<ScheduleModel>>>,
    String>((ref, resourceId) => ResourceScheduleMapNotifier(ref, resourceId));

