import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonHeader extends StatefulWidget implements PreferredSizeWidget {
  const CommonHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false, // ← falseにしておく（Stackで中央揃えするため）
      title: Stack(
        alignment: Alignment.center,
        children: [
          // 左メニュー
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: SvgPicture.asset('assets/icons/menu.svg', width: 25, height: 25),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),

          // 中央タイトル
          Center(
            child: Text(
              'Fj',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),

          // 右アイコン群
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min, // ← これで右アイコンがはみ出さないように
              children: [
                SvgPicture.asset('assets/icons/search.svg', width: 25, height: 25),
                const SizedBox(width: 14),
                SvgPicture.asset('assets/icons/bell.svg', width: 25, height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


