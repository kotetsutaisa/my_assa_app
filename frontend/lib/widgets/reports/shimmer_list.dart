import 'package:flutter/material.dart';

/// 簡易ローディング（お好みで shimmer 等に差し替え可）
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: 6,
      itemBuilder: (_, i) {
        return Container(
          height: 84,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
