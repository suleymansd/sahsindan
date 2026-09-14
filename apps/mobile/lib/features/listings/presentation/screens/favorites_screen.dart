import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/page_controls.dart';
import '../../../../shared/widgets/verification_required_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/listings_providers.dart';
import '../widgets/listing_row.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isVerified) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Favoriler'),
          backgroundColor: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.separator)),
        ),
        child: SafeArea(
          child: VerificationRequiredView(
            message: 'Favorileri kullanmak icin hesabini dogrulaman gerekiyor.',
            next: '/app/listings/favorites',
          ),
        ),
      );
    }

    final offset = ref.watch(favoritesOffsetProvider);
    final asyncItems = ref.watch(favoritesProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: asyncItems.when(
          data: (items) {
            return CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Favoriler'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => ref.invalidate(favoritesProvider),
                    child: const Icon(CupertinoIcons.refresh, size: 22, color: AppColors.primary),
                  ),
                  border: const Border(bottom: BorderSide(color: AppColors.separator)),
                  backgroundColor: AppColors.surface,
                ),
                SliverToBoxAdapter(child: PageControls(offset: offset, count: items.length, onChange: (value) => ref.read(favoritesOffsetProvider.notifier).state = value)),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'Favori yok',
                      description: 'Begenilen ilanlar burada gorunur.',
                      icon: CupertinoIcons.heart,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final listing = items[i];
                        return ListingRow(
                          listing: listing,
                          onTap: () => context.go('/app/listings/${listing.id}'),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          error: (e, _) {
            if (isForbiddenError(e)) {
              return VerificationRequiredView(
                message: 'Favorileri kullanmak icin hesabini dogrulaman gerekiyor.',
                next: '/app/listings/favorites',
                onRetry: () => ref.invalidate(favoritesProvider),
              );
            }
            return AppErrorView(
              title: 'Favoriler yuklenemedi',
              description: friendlyErrorText(e),
              onRetry: () => ref.invalidate(favoritesProvider),
            );
          },
          loading: () => const AppLoading(),
        ),
      ),
    );
  }
}
