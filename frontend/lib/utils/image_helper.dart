import 'package:frontend/utils/constants.dart';

String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst('/api/', '');
    return '$base$path';
  }