import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/utils/constants.dart';

// プロバイダー
import '../providers/current_page_provider.dart';

// タブページ
import '../screens/home_tab_page.dart';
import '../screens/timeline/timeline_tab_page.dart';
import '../screens/worksite_tab_page.dart';
import '../screens/schedule_tab_page.dart';
import '../screens/chat/chat_list_page.dart';
import '../screens/profile/profile_tab_page.dart';

class CustomTabBar extends ConsumerWidget {
  const CustomTabBar({super.key});

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 今表示しているページ
    final currentPage = ref.watch(currentPageProvider);

    // 今どのタブが選ばれているかを特定（index化する）
    int currentIndex = _getCurrentTabIndex(currentPage);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          // タップされたらページを切り替える！
          ref.read(currentPageProvider.notifier).state = _getTabPageFromIndex(index);
        },
        items: [
          _buildTabBarItem(context, currentIndex, 0, 'ホーム', 'assets/icons/home.svg', 'assets/icons/bold_home.svg'),
          _buildTabBarItem(context, currentIndex, 1, 'タイムライン', 'assets/icons/timeline.svg', 'assets/icons/bold_timeline.svg'),
          _buildTabBarItem(context, currentIndex, 2, '日報', 'assets/icons/worksite.svg', 'assets/icons/bold_worksite.svg'),
          _buildTabBarItem(context, currentIndex, 3, 'スケジュール', 'assets/icons/schedule.svg', 'assets/icons/bold_schedule.svg'),
          _buildTabBarItem(context, currentIndex, 4, 'チャット', 'assets/icons/chat.svg', 'assets/icons/bold_chat.svg'),
          _buildTabBarItem(context, currentIndex, 5, 'プロフィール', 'assets/icons/profile.svg', 'assets/icons/bold_profile.svg'),
        ],
      ),
    );
  }

  // 選択中タブのindexを判定する関数
  int _getCurrentTabIndex(Widget currentPage) {
    if (currentPage is HomeTabPage) return 0;
    if (currentPage is TimelineTabPage) return 1;
    if (currentPage is WorksiteTabPage) return 2;
    if (currentPage is ScheduleTabPage) return 3;
    if (currentPage is ChatListPage) return 4;
    if (currentPage is ProfileTabPage) return 5;
    return 0; // デフォルト
  }

  // indexからページを返す関数
  Widget _getTabPageFromIndex(int index) {
    switch (index) {
      case 0:
        return const HomeTabPage();
      case 1:
        return const TimelineTabPage();
      case 2:
        return const WorksiteTabPage();
      case 3:
        return const ScheduleTabPage();
      case 4:
        return const ChatListPage();
      case 5:
        return const ProfileTabPage();
      default:
        return const HomeTabPage();
    }
  }

  // タブのアイテムUI
  BottomNavigationBarItem _buildTabBarItem(
    BuildContext context,
    int currentIndex,
    int index,
    String label,
    String assetPath,
    String boldAssetPath,
  ) {
    final bool isSelected = currentIndex == index;
    final String iconPath = isSelected ? boldAssetPath : assetPath;

    return BottomNavigationBarItem(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round())
              : Colors.transparent,
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 25,
            height: 25,
          ),
        ),
      ),
      label: label,
    );
  }
}

