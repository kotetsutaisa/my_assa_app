import 'package:flutter/material.dart';

class LabelWithWidgetRow extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget time;
  final VoidCallback? onTimeTap;

  const LabelWithWidgetRow({
    super.key,
    required this.label,
    required this.child,
    required this.time,
    this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.outline,
      borderRadius: BorderRadius.circular(8),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: boxDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 40),
                  child: child
                ), // 日付ピッカーなど
                const SizedBox(width: 8),
                InkWell(
                  onTap: onTimeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: boxDecoration,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    child: time,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
