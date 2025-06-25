import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedule_model.dart';

final selectedScheduleProvider =
    StateProvider<ScheduleModel?>((ref) => null);  // null = 未選択
