import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/routing/verification_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/listing_photo.dart';
import '../../../../shared/widgets/listing_spec.dart';
import '../providers/comparison_provider.dart';
import '../providers/favorites_state.dart';

class ListingRow extends ConsumerWidget {
  const ListingRow(
      {super.key,
      required this.listing,
      required this.onTap,
      this.showFavorite = true});

  final Listing listing;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    final fav = ref.watch(favoritesControllerProvider);
    final favCtrl = ref.read(favoritesControllerProvider.notifier);

    final photo = listing.photos.isNotEmpty ? listing.photos.first.url : null;
    final url = photo == null
        ? null
        : resolvePublicUrl(
            publicBaseUrl: cfg.publicBaseUrl, maybeRelative: photo);
    final compared =
        ref.watch(comparisonProvider).any((item) => item.id == listing.id);
    final isFav = fav.ids.contains(listing.id);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.separator)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(
                aspectRatio: 16 / 10, child: ListingPhotoView(url: url)),
            Positioned(
                left: 12,
                bottom: 12,
                child: _TrustPill(score: listing.owner.trustScore)),
          ]),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(listing.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          if (showFavorite)
                            IconButton(
                              tooltip:
                                  isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                              onPressed: fav.loading
                                  ? null
                                  : () async {
                                      if (!VerificationGate.ensureVerified(
                                        context: context,
                                        ref: ref,
                                        message:
                                            'Favoriye eklemek icin hesabini dogrulaman gerekiyor.',
                                      )) {
                                        return;
                                      }
                                      try {
                                        await favCtrl.toggle(listing.id);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      friendlyErrorText(e))));
                                        }
                                      }
                                    },
                              icon: Icon(isFav
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart),
                              color: isFav
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                        ]),
                    const SizedBox(height: 4),
                    Text(listing.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: ListingSpec(
                              label: 'Fiyat',
                              value: '${listingNumber(listing.price)} TL')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ListingSpec(
                              label: 'Konum', value: listing.district)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!ref
                                .read(comparisonProvider.notifier)
                                .toggle(listing)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'En fazla 3 ilan karşılaştırabilirsiniz. Önce seçtiğiniz bir ilanı çıkarın.')));
                            }
                          },
                          icon: Icon(
                              compared
                                  ? Icons.check_rounded
                                  : Icons.compare_arrows_rounded,
                              size: 18),
                          label: Text(compared
                              ? 'Karşılaştırmaya eklendi'
                              : 'Karşılaştırmaya Ekle'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: compared
                                  ? AppColors.success
                                  : AppColors.primary,
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        )),
                  ])),
        ]),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.success
        : (score >= 60 ? AppColors.warning : AppColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.pillBorder(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.shield_lefthalf_fill, size: 14, color: color),
          const SizedBox(width: 6),
          Text('Güven skoru: $score',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
