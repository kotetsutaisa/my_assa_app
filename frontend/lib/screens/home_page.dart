import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//共通パーツ
import '../widgets/common_header.dart';     // ヘッダー
import '../widgets/Common_tab_bar.dart';    // ボトムタブバー 
import '../widgets/common_drawer.dart';     // ハンバーガーメニュー

// タブページ
import './home_tab_page.dart';     // ホームページ
import './timeline_tab_page.dart'; // タイムラインページ
import './worksite_tab_page.dart'; // 日報ページ
import './schedule_tab_page.dart'; // スケジュールページ
import './chat_tab_page.dart';     // チャットページ
import './profile_tab_page.dart';  // プロフィールページ

// プロバイダー
import '../providers/tab_index_provider.dart'; //タブバー

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // タブページリスト
  final _pages = [
    HomeTabPage(),
    TimelineTabPage(),
    WorksiteTabPage(),
    ScheduleTabPage(),
    ChatTabPage(),
    ProfileTabPage(),
  ];

  @override
  Widget build(BuildContext context) {

    // タブバーのインデックスプロバイダー
    final currentIndex = ref.watch(tabIndexProvider);

    return Scaffold(
      appBar: const CommonHeader(),
      drawer: const CommonDrawer(),

      // インデックスに応じたページ表示
      body: _pages[currentIndex],
      // ボトムタブバー設置
      bottomNavigationBar: const CustomTabBar(),
    );
  }
}
