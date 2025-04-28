import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/sub_header.dart';

class HomeTabPage extends ConsumerStatefulWidget {
  const HomeTabPage({super.key});

  @override
  ConsumerState<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends ConsumerState<HomeTabPage> {
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
                        backgroundImage: NetworkImage(
                          'http://10.0.2.2:8000${user!.iconimg}',
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Theme.of(context).primaryColor,
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
          Row(
            children: [
              
            ],
          ),
        ],
      ),
    );
  }
}
