import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/screens/company/company_page.dart';
import 'package:frontend/screens/invitation_page.dart';
import 'package:frontend/screens/new_work_page.dart';
import 'package:frontend/screens/site/site_list_page.dart';
import 'package:frontend/screens/track_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/column_button.dart';
import '../providers/user_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/sub_header.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTabPage extends ConsumerStatefulWidget {
  const HomeTabPage({super.key});

  @override
  ConsumerState<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends ConsumerState<HomeTabPage> {

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }
  

  @override
  Widget build(BuildContext context) {
    // ログインユーザー情報を取得
    final user = ref.watch(userProvider);

    return Scaffold(
      body: Column(
        children: [
          Center(
            child: SubHeader(
              title: 'ホーム',
              decoration: const BoxDecoration(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          // ホームヘッダー
          Container(
            height: 70,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (user?.iconimg != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: CachedNetworkImageProvider(
                          user!.iconimg!.startsWith('http')
                              ? user.iconimg!
                              : resolveImageUrl(user.iconimg!),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  const SizedBox(width: 20),
                  Text(
                    user?.username ?? 'ゲスト',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    user?.accountId ?? '',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  Spacer(),

                  // 歯車アイコンボタン
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/setting.svg',
                      width: 25,
                      height: 25,
                    ),
                    onPressed: () {
                      // 設定画面に飛ばすとか
                    },
                  ),
                ],
              ),
            ),
          ),

          // メイン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true, // Column内で使うために必要
              physics: const NeverScrollableScrollPhysics(), // スクロールしない
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                ColumnButton(
                  iconPath: 'assets/icons/company.svg',
                  label: '会社メンバー',
                  onTap: () => ref.read(currentPageProvider.notifier).state = const CompanyPage(),
                ),
                ColumnButton(
                  iconPath: 'assets/icons/site.svg',
                  label: '現場',
                  onTap: () => ref.read(currentPageProvider.notifier).state = const SiteListPage(),
                ),
                ColumnButton(
                  iconPath: 'assets/icons/track.svg',
                  label: '搬入・搬出',
                  onTap: () => ref.read(currentPageProvider.notifier).state = const TrackPage(),
                ),
                ColumnButton(
                  iconPath: 'assets/icons/invitation.svg',
                  label: '招待',
                  onTap: () => ref.read(currentPageProvider.notifier).state = const InvitePage(),
                ),
                ColumnButton(
                  iconPath: 'assets/icons/new_work.svg',
                  label: '新規入場',
                  onTap: () => ref.read(currentPageProvider.notifier).state = const NewWorkPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
