import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../providers/tab_index_provider.dart';

// タブバーのUIクラス
class CustomTabBar extends ConsumerWidget {
  const CustomTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のタブインデックスを監視
    final currentIndex = ref.watch(tabIndexProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline, // ここ好きな色！
            width: 1, // 太さ
          ),
        ),
      ),
    
      child: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          // タップされたら更新
          ref.read(tabIndexProvider.notifier).state = index;
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
        width: 40, // 丸背景のサイズ
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()) // 選択中だけグレー
              : Colors.transparent, // 選択されてない時は背景なし
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
