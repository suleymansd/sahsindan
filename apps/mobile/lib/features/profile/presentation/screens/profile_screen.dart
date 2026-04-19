import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_section.dart';
import '../../../../shared/widgets/app_cell.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../shared/models/user.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final trustAsync = ref.watch(trustBreakdownProvider);

    final trustChildren = trustAsync.when<List<Widget>>(
      data: (t) => [
        AppCell(title: 'Toplam', subtitle: '${t.total}', icon: CupertinoIcons.chart_bar, trailing: const SizedBox.shrink()),
        AppCell(title: 'Base', subtitle: '${t.base}', icon: CupertinoIcons.circle_grid_hex, trailing: const SizedBox.shrink()),
        AppCell(title: 'Meslek', subtitle: '${t.profession}', icon: CupertinoIcons.briefcase, trailing: const SizedBox.shrink()),
        AppCell(
          title: 'Tamamlanan randevu',
          subtitle: '+${t.completedAppointments}',
          icon: CupertinoIcons.calendar_badge_plus,
          trailing: const SizedBox.shrink(),
        ),
        AppCell(
          title: 'No-show cezasi',
          subtitle: '-${t.noShowPenalty}',
          icon: CupertinoIcons.hand_raised_slash,
          trailing: const SizedBox.shrink(),
        ),
        AppCell(title: 'Rapor cezasi', subtitle: '-${t.reportPenalty}', icon: CupertinoIcons.flag, trailing: const SizedBox.shrink()),
      ],
      error: (e, _) => [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppErrorView(
            title: 'Trust yuklenemedi',
            description: friendlyErrorText(e),
            onRetry: () => ref.invalidate(trustBreakdownProvider),
          ),
        ),
      ],
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(height: 120, child: AppLoading()),
        ),
      ],
    );

    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Profil'),
              border: const Border(bottom: BorderSide(color: AppColors.separator)),
              backgroundColor: AppColors.surface,
              trailing: user?.isAdmin == true
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.separator),
                      ),
                      child: const Text('Admin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    )
                  : null,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    if (!auth.isVerified)
                      _VerificationBanner(
                        onTap: () => context.push('/verification/status?message=Hesabini%20dogrula,%20ilan%20ver%20ve%20mesajlas.'),
                      ),
                    AppSection(
                      header: 'Hesap',
                      children: [
                        AppCell(
                          icon: CupertinoIcons.person_crop_circle,
                          title: user?.email ?? '-',
                          subtitle: user == null ? null : 'Rol: ${user.role}  •  Durum: ${user.status}',
                          trailing: const SizedBox.shrink(),
                        ),
                        AppCell(
                          icon: CupertinoIcons.checkmark_shield,
                          title: auth.isVerified ? 'Dogrulanmis' : 'Dogrulanmamis',
                          subtitle: auth.isVerified ? 'Tum islemler acik.' : 'Ilan ver, mesajlas, randevu olusturmak icin dogrulama gerekli.',
                          trailing: auth.isVerified
                              ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.primary, size: 18)
                              : const Icon(CupertinoIcons.chevron_forward, color: AppColors.textSecondary, size: 18),
                          onTap: auth.isVerified ? null : () => context.push('/verification/status?message=Bu%20islem%20icin%20hesabini%20dogrulaman%20gerekiyor.'),
                        ),
                        AppCell(
                          icon: CupertinoIcons.star_circle,
                          title: 'Trust score',
                          subtitle: '${user?.trustScore ?? 0}',
                          trailing: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSection(
                      header: 'Guven puani detayi',
                      children: trustChildren,
                    ),
                    const SizedBox(height: 16),
                    AppSection(
                      header: 'Kisayollar',
                      children: [
                        AppCell(
                          icon: CupertinoIcons.heart,
                          title: 'Favoriler',
                          subtitle: 'Begenilen ilanlar',
                          onTap: () => context.push('/app/listings/favorites'),
                        ),
                        AppCell(
                          icon: CupertinoIcons.square_list,
                          title: 'Ilanlarim',
                          subtitle: 'Yayinladigin ilanlar',
                          onTap: () => context.push('/app/listings/mine'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.square_arrow_right, size: 18),
                          SizedBox(width: 8),
                          Text('Cikis yap'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.separator),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_shield, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hesabini dogrula',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ilan ver ve mesajlasmak icin dogrulama gerekli.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
