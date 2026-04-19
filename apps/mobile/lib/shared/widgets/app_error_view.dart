import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_chrome.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.title, this.description, this.onRetry});

  final String title;
  final String? description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final desc = (description ?? '').trim();
    final showDebug = kDebugMode && desc.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppGlass(
            padding: const EdgeInsets.all(22),
            radius: 24,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppHeroBadgeIcon(
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    size: 68,
                    primary: AppColors.warning,
                    secondary: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(CupertinoIcons.refresh),
                      label: const Text('Tekrar dene'),
                    ),
                  ],
                  if (showDebug) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Debug: $desc',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
