import 'package:flutter/material.dart';

/// 日報機能用のタブバー（チーム / 個人）。
/// スケジュールのタブUIを踏襲し、常に2タブ表示する。
/// 左=チーム(index:0)、右=個人(index:1)
class ReportsTabBar extends StatelessWidget {
  final int tabIndex; // 0: チーム, 1: 個人
  final ValueChanged<int> onTabChanged;

  const ReportsTabBar({
    Key? key,
    required this.tabIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ← 並び順を「チーム → 個人」に
    final tabs = const <_TabSpec>[
      _TabSpec(label: 'チーム', index: 0),
      _TabSpec(label: '個人', index: 1),
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

