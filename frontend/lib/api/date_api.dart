import 'package:intl/intl.dart';

String formatPostDate(String? isoDateString) {
  if (isoDateString == null || isoDateString.isEmpty) {
    return ''; // または '不明', '--', などお好みで
  }

  try {
    final now = DateTime.now();
    final postDate = DateTime.parse(isoDateString);
    final difference = now.difference(postDate);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else {
      final formatter = DateFormat.Md('ja'); // 「3月15日」風
      return formatter.format(postDate);
    }
  } catch (e) {
    // パースできなかった場合も空文字などで返す
    return '';
  }
}

