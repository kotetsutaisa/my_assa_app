import 'package:flutter/material.dart';

/// 1日ヘッダー：← 前日 / 日付ラベル + (カレンダー) / → 翌日
class DayHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const DayHeader({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: '日付を選択',
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_today),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
