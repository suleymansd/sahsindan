import 'package:flutter/material.dart';

class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.2),
      titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.35),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}
