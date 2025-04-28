import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  const CommonHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: true, // 標準のハンバーガーもスワイプも許可
      centerTitle: true, // 中央タイトルのためtrueにしてOK
      title: Text(
        'Fj',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      actions: [
        SvgPicture.asset('assets/icons/search.svg', width: 25, height: 25),
        const SizedBox(width: 14),
        SvgPicture.asset('assets/icons/bell.svg', width: 25, height: 25),
        const SizedBox(width: 8),
      ],
    );
  }
}



