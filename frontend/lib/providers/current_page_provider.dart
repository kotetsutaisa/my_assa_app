import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 最初に表示したいページ（例：ホームタブページ）を読み込む
import '../screens/home_tab_page.dart';

// 現在表示するページを管理するプロバイダー
final currentPageProvider = StateProvider<Widget>((ref) => const HomeTabPage());
