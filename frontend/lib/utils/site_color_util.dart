import 'package:flutter/material.dart';
import 'package:frontend/constants/site_colors.dart';

/// サイト ID から決定的にカラーを返す
Color siteColor(String siteId) {
  // simple FNV-1a 64-bit hash
  var hash = 0xcbf29ce484222325;
  for (final codeUnit in siteId.codeUnits) {
    hash ^= codeUnit;
    hash *= 0x100000001b3;
  }
  final idx = hash.abs() % siteColorPalette.length;
  return siteColorPalette[idx];
}
