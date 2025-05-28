import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final void Function(String text) onSend;

  const ChatInputField({Key? key, required this.onSend}) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear(); // 入力欄をリセット
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: 'メッセージを入力',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
