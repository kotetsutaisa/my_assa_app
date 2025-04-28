import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 共通パーツを読み込む
import '../widgets/common_header.dart';
import '../widgets/common_drawer.dart';
import '../widgets/common_tab_bar.dart';

// 今表示するページ（body）を管理するプロバイダー
import '../providers/current_page_provider.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在表示するページ（Widget）を取得
    final currentPage = ref.watch(currentPageProvider);

    return Scaffold(
      appBar: const CommonHeader(),
      drawer: const CommonDrawer(),
      body: currentPage,
      bottomNavigationBar: const CustomTabBar(),
    );
  }
}
