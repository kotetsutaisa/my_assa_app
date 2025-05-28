import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/chat/chat_list_page.dart';
import 'package:frontend/providers/current_page_provider.dart';

class ChatHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String username;
  final String? userIconUrl;
  final Widget? trailing;
  final BoxDecoration? decoration;

  const ChatHeader({
    super.key,
    required this.username,
    this.userIconUrl,
    this.trailing,
    this.decoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: preferredSize.height - 1,
            decoration: decoration,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🔙 戻るボタン（左上）
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      ref.read(currentPageProvider.notifier).state = const ChatListPage();
                    },
                  ),
                ),

                // 👤 中央にアイコンと名前
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userIconUrl != null)
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(userIconUrl!),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),

                // 🔧 右側オプション（任意）
                if (trailing != null)
                  Positioned(
                    right: 0,
                    child: trailing!,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}



