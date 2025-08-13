// /lib/screens/reports/reports_root_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/reports/personal_report_timeline_page.dart';
import 'package:frontend/screens/reports/report_create_page.dart';
import 'package:frontend/screens/reports/team_report_timeline_page.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/reports/reports_tab_bar.dart';

class ReportsRootPage extends ConsumerStatefulWidget {
  const ReportsRootPage({super.key});
  @override
  ConsumerState<ReportsRootPage> createState() => _ReportsRootPageState();
}

class _ReportsRootPageState extends ConsumerState<ReportsRootPage> {
  int _tabIndex = 0; // 0: チーム, 1: 個人

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ReportsTabBar(
            tabIndex: _tabIndex,
            onTabChanged: (i) => setState(() => _tabIndex = i),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                TeamReportTimelineView(),     // ← タブ内の中身だけ
                PersonalReportTimelineView(), // ← さっき作った個人の一覧View
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: PostButton(
        onPressed: () => _openCreate(context),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportsCreatePage()),
    );
  }
}
