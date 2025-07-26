import 'package:flutter/material.dart';

class ScheduleTabBarWidget extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  /// チームタブを表示するかどうか
  final bool showTeamTab;

  const ScheduleTabBarWidget({
    Key? key,
    required this.tabIndex,
    required this.onTabChanged,
    this.showTeamTab = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // チームタブが無いのに tabIndex==1 になっていたら 0 に戻す通知
    if (!showTeamTab && tabIndex != 0) {
      // フレーム後にコールバックさせて親 State を更新（ビルド中 setState 回避）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onTabChanged(0);
      });
    }

    final tabs = <_TabSpec>[
      _TabSpec(label: '個人', index: 0),
      if (showTeamTab) _TabSpec(label: 'チーム', index: 1),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
            for (int i = 0; i < tabs.length; i++) ...[
              Expanded(child: _buildTab(context, tabs[i])),
              if (i != tabs.length - 1) const SizedBox(width: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, _TabSpec spec) {
    final isSelected = tabIndex == spec.index;

    return GestureDetector(
      onTap: () {
        if (!isSelected) onTabChanged(spec.index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          spec.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final int index;
  const _TabSpec({required this.label, required this.index});
}
