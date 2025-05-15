import 'package:intl/intl.dart';

String formatPostDate(String isoDateString) {
  final now = DateTime.now();
  final postDate = DateTime.parse(isoDateString);
  final difference = now.difference(postDate);

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}分前';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}時間前';
  } else {
    final formatter = DateFormat.Md('ja'); // 「3月15日」
    return formatter.format(postDate);
  }
}
