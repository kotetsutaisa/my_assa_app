import 'package:flutter/material.dart';

class PostButton extends StatelessWidget {
  final VoidCallback onPressed; // ボタンが押されたときに呼ぶ関数

  const PostButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, size: 30, color: Colors.white),
    );
  }
}
