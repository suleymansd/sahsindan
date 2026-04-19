import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/routing/verification_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../providers/favorites_state.dart';

class ListingRow extends ConsumerWidget {
  const ListingRow({super.key, required this.listing, required this.onTap, this.showFavorite = true});

  final Listing listing;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    final fav = ref.watch(favoritesControllerProvider);
    final favCtrl = ref.read(favoritesControllerProvider.notifier);

    final photo = listing.photos.isNotEmpty ? listing.photos.first.url : '/placeholder.png';
    final url = resolvePublicUrl(publicBaseUrl: cfg.publicBaseUrl, maybeRelative: photo);
    final isFav = fav.ids.contains(listing.id);

    return GestureDetector(
      onTap: onTap,
      child: AppGlass(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    url,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: AppColors.surfaceMuted,
                      child: const Icon(CupertinoIcons.car, color: AppColors.textSecondary),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Canli', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₺${listing.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${listing.city} • ${listing.district}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TrustPill(score: listing.owner.trustScore),
                    ],
                  ),
                ],
              ),
            ),
            if (showFavorite) ...[
              const SizedBox(width: 10),
              IconButton(
                onPressed: fav.loading
                    ? null
                    : () async {
                        if (!VerificationGate.ensureVerified(
                          context: context,
                          ref: ref,
                          message: 'Favoriye eklemek icin hesabini dogrulaman gerekiyor.',
                        )) {
                          return;
                        }
                        try {
                          await favCtrl.toggle(listing.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
                          }
                        }
                      },
                icon: Icon(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart),
                color: isFav ? AppColors.danger : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success : (score >= 60 ? AppColors.warning : AppColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pillBg(color),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.pillBorder(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.shield_lefthalf_fill, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
