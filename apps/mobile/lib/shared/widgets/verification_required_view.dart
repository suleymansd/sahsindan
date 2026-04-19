import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'app_chrome.dart';

class VerificationRequiredView extends StatelessWidget {
  const VerificationRequiredView({
    super.key,
    required this.message,
    this.next,
    this.onRetry,
  });

  final String message;
  final String? next;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final qp = <String, String>{'message': message};
    if (next != null && next!.trim().isNotEmpty) qp['next'] = next!.trim();

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
                const AppHeroBadgeIcon(icon: CupertinoIcons.lock_fill, size: 68),
                const SizedBox(height: 16),
                Text(
                  'Dogrulama Gerekli',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push(Uri(path: '/verification/status', queryParameters: qp).toString()),
                  child: const Text('Dogrulamaya git'),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(CupertinoIcons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
                const SizedBox(height: 2),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Geri'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
