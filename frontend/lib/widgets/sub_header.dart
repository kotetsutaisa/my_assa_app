import 'package:flutter/material.dart';

class SubHeader extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Widget? trailing;
  final BoxDecoration? decoration;

  const SubHeader({
    super.key,
    required this.title,
    this.style,
    this.trailing,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: decoration ??
          const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中央テキスト
          Center(
            child: Text(
              title,
              style: style ?? Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}


