import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const SizedBox(height: 8),
            const Center(
              child: AppHeroBadgeIcon(
                icon: Icons.directions_car_filled_rounded,
                size: 88,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.appName,
              textAlign: TextAlign.center,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Dogrulanmis kisiyle, guven odakli ikinci el arac deneyimi.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            const AppGlass(
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BenefitRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Dogrulanmis hesaplar',
                    subtitle: 'Sahte profil riskini azaltan guven bariyeri.',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.flash_on_rounded,
                    title: 'Hizli akis',
                    subtitle: 'Mesajlasma ve randevu tek uygulama akisi icinde.',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.security_rounded,
                    title: 'Takip edilebilir guven skoru',
                    subtitle: 'Satici davranisi ve puan sinyalleri acik gorunur.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const SizedBox(width: double.infinity, child: Center(child: Text(S.loginTitle))),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              child: const SizedBox(width: double.infinity, child: Center(child: Text(S.registerTitle))),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/forgot'),
              child: const Text(S.forgotTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeroBadgeIcon(icon: icon, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
