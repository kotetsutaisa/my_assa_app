import 'package:flutter/material.dart';

class ScheduleTabBarWidget extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const ScheduleTabBarWidget({
    Key? key,
    required this.tabIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab("個人", 0, context),
          const SizedBox(width: 8),
          _buildTab("チーム", 1, context),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, BuildContext context) {
    final isSelected = tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}