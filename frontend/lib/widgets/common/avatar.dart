// lib/widgets/common/avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 画像URLがあればそれを使い、無ければ背景=primary・中身=personアイコンで描画
Widget buildAvatar({
  required BuildContext context,
  String? imageUrl,
  double radius = 18,
  IconData fallbackIcon = Icons.person,
  Color? backgroundColor,
  Color? iconColor,
  String Function(String)? resolveUrl, // 画像URL補正が必要な場合だけ渡す
}) {
  final hasImg = imageUrl != null && imageUrl.isNotEmpty;
  final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
  final fg = iconColor ?? Colors.white;
  final resolved = hasImg && resolveUrl != null ? resolveUrl(imageUrl) : imageUrl;

  return CircleAvatar(
    radius: radius,
    backgroundImage: hasImg ? CachedNetworkImageProvider(resolved!) : null,
    backgroundColor: hasImg ? null : bg,
    child: hasImg
        ? null
        : Icon(
            fallbackIcon,
            color: fg,
            size: radius, // 好みで radius*0.9 などに調整
          ),
  );
}

