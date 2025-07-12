import 'package:flutter_riverpod/flutter_riverpod.dart';

/// チームカレンダーで最後にタップされた日付（初期値 = 今日）
final selectedTeamDateProvider =
    StateProvider<DateTime>((_) => DateTime.now());