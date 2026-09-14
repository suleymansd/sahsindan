import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAnimatedBackdrop extends StatelessWidget {
  const AppAnimatedBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.background, child: child);
}

class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: AppColors.separator),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AppHeroBadgeIcon extends StatelessWidget {
  const AppHeroBadgeIcon({
    super.key,
    required this.icon,
    this.size = 54,
    this.primary = AppColors.primary,
    this.secondary = AppColors.secondary,
  });

  final IconData icon;
  final double size;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: secondary.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: primary, size: size * 0.46),
    );
  }
}
