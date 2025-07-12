// lib/providers/selected_team_date_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 個人カレンダーで最後にタップされた日付（初期値 = 今日）
final selectedDateProvider =
    StateProvider<DateTime>((_) => DateTime.now());
