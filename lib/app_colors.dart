import 'package:flutter/material.dart';

// ─── Colors (다크모드 대응) ──────────────────────────────────────────────────
class AppColors {
  static bool isDark = false;
  // 다크모드 무관 — static const 유지
  static const Color accent  = Color(0xFF3A78C9);
  static const Color accent2 = Color(0x243A78C9);
  static const Color gold    = Color(0xFFA07828);
  static const Color green   = Color(0xFF2A9C70);
  static const Color red     = Color(0xFFD94040);
  // 다크모드 대응 — getter
  static Color get bg    => isDark ? const Color(0xFF13111C) : const Color(0xFFF0EDE6);
  static Color get panel => isDark ? const Color(0xFF1C1A2A) : const Color(0xEBFCFAF7);
  static Color get t1    => isDark ? const Color(0xFFEEEDF8) : const Color(0xFF181620);
  static Color get t2    => isDark ? const Color(0xFF9895B0) : const Color(0xFF58566A);
  static Color get t3    => isDark ? const Color(0xFF5C5A74) : const Color(0xFFA09EB8);
  static Color get border      => isDark ? const Color(0x503A78C9) : const Color(0x243A78C9);
  static Color get borderLight => isDark ? const Color(0x25FFFFFF) : const Color(0xCCFFFFFF);
}
