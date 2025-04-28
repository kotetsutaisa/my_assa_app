import 'package:flutter_riverpod/flutter_riverpod.dart';

// 現在選択されているタブのインデックスを管理するProvider
final tabIndexProvider = StateProvider<int>((ref) => 0);
