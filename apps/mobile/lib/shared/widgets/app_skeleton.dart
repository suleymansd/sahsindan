import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.height = 16, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.separator.withValues(alpha: 0.72),
      highlightColor: Colors.white.withValues(alpha: 0.75),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ListingRowSkeleton extends StatelessWidget {
  const ListingRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.separator),
      ),
      child: const Row(
        children: <Widget>[
          AppSkeleton(height: 72, width: 72, radius: 16),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSkeleton(height: 14, width: 220),
                SizedBox(height: 10),
                AppSkeleton(height: 14, width: 160),
                SizedBox(height: 10),
                AppSkeleton(height: 12, width: 120),
              ],
            ),
          ),
          SizedBox(width: 12),
          AppSkeleton(height: 24, width: 44, radius: 999),
        ],
      ),
    );
  }
}
