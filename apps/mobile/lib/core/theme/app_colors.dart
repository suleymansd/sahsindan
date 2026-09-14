import 'package:flutter/material.dart';

class AppColors {
  static const backgroundTop = Color(0xFFF7F9FB);
  static const backgroundBottom = Color(0xFFF7F9FB);
  static const background = Color(0xFFF7F9FB);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceStrong = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const navBar = Color(0xFFFFFFFF);
  static const separator = Color(0xFFE2E8F0);

  static const textPrimary = Color(0xFF1A2B47);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const primary = Color(0xFF1A2B47);
  static const primaryDeep = Color(0xFF031631);
  static const secondary = Color(0xFF00D1FF);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF29F05);

  static const shadow = Color(0x1F16305A);
  static const glowBlue = Color(0xFF8FB8FF);
  static const glowMint = Color(0xFF7BE0D2);

  static Color pillBg(Color fg) => fg.withValues(alpha: 0.12);
  static Color pillBorder(Color fg) => fg.withValues(alpha: 0.30);
}
