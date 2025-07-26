import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/providers/my_personal_schedule_provider.dart';
import 'package:frontend/providers/selected_date_provider.dart';
import 'package:frontend/providers/selected_team_date_provider.dart';
import 'package:frontend/providers/team_schedule_provider.dart';   // ★ 追加
import 'package:frontend/providers/user_provider.dart';

import 'package:frontend/screens/schedule/create_schedule_page.dart';
import 'package:frontend/screens/schedule/create_team_schedule_page.dart';

import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/schedule_widget/personal_schedule_tab.dart';
import 'package:frontend/widgets/schedule_widget/team_schedule_tab.dart';  // ★ 追加
import 'package:frontend/widgets/schedule_widget/schedule_tabbar_widget.dart';

class ScheduleTabPage extends ConsumerStatefulWidget {
  const ScheduleTabPage({super.key});

  @override
  ConsumerState<ScheduleTabPage> createState() => _ScheduleTabPageState();
}

class _ScheduleTabPageState extends ConsumerState<ScheduleTabPage> {
  int _tabIndex = 0;
  bool _hasFetched = false;

  late final PageController _pageController;          // ★ PageView 用

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      // ✅ 個人・チーム両方まとめて fetch
      final today  = DateTime.now();
      final start  = DateTime(today.year, today.month, 1);
      final end    = DateTime(today.year, today.month + 1, 0);

      ref.read(myPersonalScheduleMapProvider.notifier).fetch(start, end);
      final user = ref.read(userProvider);
      if (user?.hasTeam == true) {
        ref.read(teamScheduleMapProvider.notifier).fetch(start, end);
      }

      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    print(user?.teams);
    final hasTeam = user?.hasTeam ?? false;

    // チームが無いのにタブ index が 1 なら 0 に戻す
    if (!hasTeam && _tabIndex != 0) {
      _tabIndex = 0;
    }

    // 表示ページを構築
    final pages = <Widget>[
      const PersonalScheduleTab(),
      if (hasTeam) const TeamScheduleTab(),
    ];

    // PageController の現在ページが範囲外になった場合の保険
    if (_pageController.positions.isNotEmpty &&
        _pageController.page != null &&
        _pageController.page!.round() >= pages.length) {
      // 先に jumpToPage で 0 に戻す
      _pageController.jumpToPage(0);
    }


    return Scaffold(
      body: Column(
        children: [
          // ---------------- タブバー ----------------
          ScheduleTabBarWidget(
            tabIndex: _tabIndex,
            showTeamTab: hasTeam,
            onTabChanged: (index) {
              setState(() => _tabIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),

          // ---------------- ページ切替 ----------------
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _tabIndex = index);
              },
              children: pages,
            ),
          ),
        ],
      ),

      // ---------------- 追加ボタン ----------------
      floatingActionButton: PostButton(
        onPressed: () {
          final selectedDate = ref.read(selectedDateProvider);
          final selectedTeamDate = ref.read(selectedTeamDateProvider);

          final route = _tabIndex == 0
              ? CreateSchedulePage(initialDate: selectedDate)         // 個人タブ
              : CreateTeamSchedulePage(initialDate: selectedTeamDate);    // ★ チームタブ
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => route),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

