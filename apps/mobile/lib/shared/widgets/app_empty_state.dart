import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_chrome.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = CupertinoIcons.info,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppGlass(
            padding: const EdgeInsets.all(22),
            radius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppHeroBadgeIcon(icon: icon, size: 68),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                if (primaryLabel != null && onPrimary != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onPrimary, child: Text(primaryLabel!)),
                ],
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
