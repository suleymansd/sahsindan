import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAnimatedBackdrop extends StatefulWidget {
  const AppAnimatedBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AppAnimatedBackdrop> createState() => _AppAnimatedBackdropState();
}

class _AppAnimatedBackdropState extends State<AppAnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
                ),
              ),
            ),
            _GlowBlob(
              size: 270,
              alignment: Alignment(-0.95 + (0.20 * t), -1.05 + (0.10 * t)),
              colors: const [AppColors.glowBlue, Color(0x000B66FF)],
            ),
            _GlowBlob(
              size: 240,
              alignment: Alignment(1.0 - (0.18 * t), -0.40 + (0.12 * t)),
              colors: const [AppColors.glowMint, Color(0x0000A39A)],
            ),
            _GlowBlob(
              size: 300,
              alignment: Alignment(-0.5 + (0.14 * t), 1.10 - (0.10 * t)),
              colors: const [Color(0x80D2E4FF), Color(0x00D2E4FF)],
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.alignment, required this.colors});

  final double size;
  final Alignment alignment;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: math.pi / 18,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.28),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceStrong.withValues(alpha: 0.94),
            AppColors.surface.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.separator.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.70),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.46),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(-2, -2),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}
