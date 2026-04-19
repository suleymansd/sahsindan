import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/verification_required_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/listings_providers.dart';
import '../widgets/listing_row.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isVerified) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Ilanlarim'),
          backgroundColor: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.separator)),
        ),
        child: SafeArea(
          child: VerificationRequiredView(
            message: 'Ilan yonetimi icin hesabini dogrulaman gerekiyor.',
            next: '/app/listings/mine',
          ),
        ),
      );
    }

    final asyncItems = ref.watch(myListingsProvider);
    final query = ref.watch(myListingsQueryProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: asyncItems.when(
          data: (items) {
            return CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Ilanlarim'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => ref.invalidate(myListingsProvider),
                    child: const Icon(CupertinoIcons.refresh, size: 22, color: AppColors.primary),
                  ),
                  border: const Border(bottom: BorderSide(color: AppColors.separator)),
                  backgroundColor: AppColors.surface,
                ),
                SliverToBoxAdapter(
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Tum'),
                                selected: query.state == null,
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: null),
                              ),
                              ChoiceChip(
                                label: const Text('Taslak'),
                                selected: query.state == 'DRAFT',
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: 'DRAFT'),
                              ),
                              ChoiceChip(
                                label: const Text('Yayinda'),
                                selected: query.state == 'PUBLISHED',
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: 'PUBLISHED'),
                              ),
                              ChoiceChip(
                                label: const Text('Arsiv'),
                                selected: query.state == 'ARCHIVED',
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: 'ARCHIVED'),
                              ),
                              ChoiceChip(
                                label: const Text('Satildi'),
                                selected: query.state == 'SOLD',
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: 'SOLD'),
                              ),
                              ChoiceChip(
                                label: const Text('Reddedildi'),
                                selected: query.state == 'REJECTED',
                                onSelected: (_) => ref.read(myListingsQueryProvider.notifier).state = query.copyWith(state: 'REJECTED'),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            value: query.includeInactive,
                            onChanged: (v) {
                              ref.read(myListingsQueryProvider.notifier).state = query.copyWith(includeInactive: v, state: query.state);
                              ref.invalidate(myListingsProvider);
                            },
                            title: const Text('Yayinda olmayanlari da goster'),
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'Henuz ilan yok',
                      description: 'Ilk ilanini olusturmak icin dogrulama yapabilirsin.',
                      icon: CupertinoIcons.square_list,
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
                message: 'Ilan yonetimi icin hesabini dogrulaman gerekiyor.',
                next: '/app/listings/mine',
                onRetry: () => ref.invalidate(myListingsProvider),
              );
            }
            return AppErrorView(
              title: 'Ilanlar yuklenemedi',
              description: friendlyErrorText(e),
              onRetry: () => ref.invalidate(myListingsProvider),
            );
          },
          loading: () => const AppLoading(),
        ),
      ),
    );
  }
}
