import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ColumnButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const ColumnButton({
    Key? key,
    required this.iconPath,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 25,
            height: 25,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
