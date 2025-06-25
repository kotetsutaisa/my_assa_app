import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/my_personal_schedule_provider.dart';
import 'package:frontend/screens/schedule/create_schedule_page.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/schedule_widget/personal_schedule_tab.dart';
import 'package:frontend/widgets/schedule_widget/schedule_tabbar_widget.dart';

class ScheduleTabPage extends ConsumerStatefulWidget {
  const ScheduleTabPage({super.key});

  @override
  ConsumerState<ScheduleTabPage> createState() => _ScheduleTabPageState();
}

class _ScheduleTabPageState extends ConsumerState<ScheduleTabPage> {
  int _tabIndex = 0;
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasFetched) {
      // ✅ 一度だけfetch実行
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 0);

      ref.read(myPersonalScheduleMapProvider.notifier).fetch(start, end);
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScheduleTabBarWidget(
            tabIndex: _tabIndex,
            onTabChanged: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
          ),
          Expanded(
            child: _tabIndex == 0
                ? const PersonalScheduleTab()
                : const Center(child: Text("チームカレンダー準備中")),
          ),
        ],
      ),

      floatingActionButton: PostButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateSchedulePage(),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
