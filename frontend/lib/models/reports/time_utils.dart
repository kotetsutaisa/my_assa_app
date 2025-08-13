import 'package:flutter/material.dart';

TimeOfDay parseTimeOfDay(String s) {
  // 期待: "HH:mm:ss" or "HH:mm"
  final parts = s.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return TimeOfDay(hour: h, minute: m);
}

String formatTimeOfDay(TimeOfDay t, {bool withSeconds = true}) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return withSeconds ? '$hh:$mm:00' : '$hh:$mm';
}

DateTime parseDateOnly(String s) {
  // "YYYY-MM-DD" 想定
  final p = s.split('-');
  final y = int.parse(p[0]);
  final m = int.parse(p[1]);
  final d = int.parse(p[2]);
  return DateTime(y, m, d);
}

String formatDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
