import 'package:intl/intl.dart';

String formatPostDate(String isoDateString) {
  final now = DateTime.now();
  final postDate = DateTime.parse(isoDateString);
  final difference = now.difference(postDate);

  if (difference.inHours < 24) {
    return '${difference.inHours}時間前';
  } else {
    // 「3月15日」のようにフォーマット
    final formatter = DateFormat.Md('ja'); // 月日形式（ロケールjaで「3/15」→「3月15日」）
    return formatter.format(postDate);
  }
}