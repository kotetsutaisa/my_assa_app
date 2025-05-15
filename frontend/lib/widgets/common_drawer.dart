import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/utils/token_manager.dart';

// プロバイダー
import '../providers/user_provider.dart'; // ログインユーザー

class CommonDrawer extends ConsumerStatefulWidget {
  const CommonDrawer({super.key});

  @override
  ConsumerState<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends ConsumerState<CommonDrawer> {

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    // ログインユーザー情報を取得
    final user = ref.watch(userProvider);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // DrawerHeader
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user?.iconimg != null
                          ? CachedNetworkImageProvider(
                              user!.iconimg!.startsWith('http')
                                  ? user.iconimg!
                                  : resolveImageUrl(user.iconimg!),
                            )
                          : null,
                      backgroundColor: const Color.fromARGB(255, 45, 45, 45),
                      child: user?.iconimg == null
                          ? const Icon(Icons.person, size: 25, color: Colors.white)
                          : null,
                    ),
                    IconButton(
                      icon: SvgPicture.asset('assets/icons/setting.svg'),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  user?.username ?? 'ゲストユーザー',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.accountId ?? '',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // ここからメニュー
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero, // ← これ忘れず！
              children: [
                ListTile(
                  leading: SvgPicture.asset('assets/icons/profile.svg', width: 25, height: 25),
                  title: Text('プロフィール', style: Theme.of(context).textTheme.bodyLarge),
                ),
                ListTile(
                  leading: SvgPicture.asset('assets/icons/ai.svg', width: 25, height: 25),
                  title: Text('AI設定', style: Theme.of(context).textTheme.bodyLarge),
                ),
                ListTile(
                  leading: SvgPicture.asset('assets/icons/bell.svg', width: 25, height: 25),
                  title: Text('通知設定', style: Theme.of(context).textTheme.bodyLarge),
                ),
                ListTile(
                  leading: SvgPicture.asset('assets/icons/schedule.svg', width: 25, height: 25),
                  title: Text('スケジュール設定', style: Theme.of(context).textTheme.bodyLarge),
                ),
                ListTile(
                  leading: SvgPicture.asset('assets/icons/app_assist.svg', width: 25, height: 25),
                  title: Text('アプリの使い方', style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          ),

          // ← ここが一番下に固定される！
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: SvgPicture.asset('assets/icons/logout.svg', width: 25, height: 25),
              title: Text('ログアウト', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () async {
                await deleteTokens();
                ref.read(userProvider.notifier).clearUser(); // Riverpod流でuser情報クリア！
                Navigator.pushReplacementNamed(context, '/login'); // ログイン画面に飛ばす
              },
            ),
          ),
        ],
      ),
    );
  }
}
