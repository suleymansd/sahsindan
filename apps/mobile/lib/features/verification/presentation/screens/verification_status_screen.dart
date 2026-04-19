import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key, this.gateMessage, this.next});

  final String? gateMessage;
  final String? next;

  @override
  ConsumerState<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends ConsumerState<VerificationStatusScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      setState(() => _loading = true);
      await ref.read(authControllerProvider.notifier).refreshVerificationStatus();
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final status = auth.isVerified
        ? 'APPROVED'
        : (auth.verification?.status.toUpperCase().trim() ?? 'NOT_SUBMITTED');
    final reason = auth.verification?.reason;

    String title;
    String desc;
    IconData icon;
    Color primary;
    Color secondary;

    switch (status) {
      case 'APPROVED':
      case 'VERIFIED':
        title = 'Dogrulama tamamlandi';
        desc = 'Hesabin dogrulandi. Artik tum islemleri yapabilirsin.';
        icon = Icons.verified;
        primary = AppColors.success;
        secondary = AppColors.secondary;
        break;
      case 'REJECTED':
        title = 'Dogrulama reddedildi';
        desc = reason ?? 'Basvuru reddedildi.';
        icon = Icons.cancel;
        primary = AppColors.danger;
        secondary = AppColors.warning;
        break;
      case 'NEEDS_MORE_INFO':
        title = 'Ek bilgi gerekiyor';
        desc = reason ?? 'Basvurun icin ek bilgi/foto isteniyor.';
        icon = Icons.info;
        primary = AppColors.warning;
        secondary = AppColors.primary;
        break;
      case 'PENDING':
        title = 'Inceleme asamasinda';
        desc = 'Basvurun alinmistir. Moderator incelemesi bekleniyor.';
        icon = Icons.hourglass_bottom;
        primary = AppColors.warning;
        secondary = AppColors.secondary;
        break;
      case 'NOT_SUBMITTED':
      default:
        title = 'Dogrulama gerekiyor';
        desc = 'Bazi islemler icin dogrulama basvurusu gondermen gerekiyor.';
        icon = Icons.shield;
        primary = AppColors.primary;
        secondary = AppColors.secondary;
    }

    final canContinue = auth.isVerified;

    return Scaffold(
      appBar: AppBar(title: const Text('Dogrulama Durumu')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if ((widget.gateMessage ?? '').trim().isNotEmpty) ...[
              AppGlass(
                radius: 18,
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.gateMessage!.trim())),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            AppGlass(
              radius: 26,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeroBadgeIcon(icon: icon, size: 74, primary: primary, secondary: secondary),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(desc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/verification/verify'),
                    child: const Text('Dogrulama baslat / guncelle'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            await ref.read(authControllerProvider.notifier).refreshVerificationStatus();
                            if (mounted) setState(() => _loading = false);
                          },
                    child: Text(_loading ? 'Yenileniyor...' : 'Yenile'),
                  ),
                  if (canContinue) ...[
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () {
                        final next = (widget.next ?? '').trim();
                        if (next.isNotEmpty) {
                          context.go(next);
                        } else {
                          context.go('/app/listings');
                        }
                      },
                      child: const Text('Devam et'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
