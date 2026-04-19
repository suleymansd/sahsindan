import 'package:flutter/material.dart';

class AppColors {
  static const backgroundTop = Color(0xFFF4F7FF);
  static const backgroundBottom = Color(0xFFE9F7F2);
  static const background = Color(0xFFF0F4FF);

  static const surface = Color(0xF7FFFFFF);
  static const surfaceStrong = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFF3FF);
  static const navBar = Color(0xECFFFFFF);
  static const separator = Color(0xFFD7E1F2);

  static const textPrimary = Color(0xFF13233D);
  static const textSecondary = Color(0xFF5D6F8E);
  static const textTertiary = Color(0xFF7E90AD);

  static const primary = Color(0xFF0B66FF);
  static const primaryDeep = Color(0xFF0A4FCA);
  static const secondary = Color(0xFF00A39A);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF179A5B);
  static const warning = Color(0xFFF29F05);

  static const shadow = Color(0x1F16305A);
  static const glowBlue = Color(0xFF8FB8FF);
  static const glowMint = Color(0xFF7BE0D2);

  static Color pillBg(Color fg) => fg.withValues(alpha: 0.12);
  static Color pillBorder(Color fg) => fg.withValues(alpha: 0.30);
}
