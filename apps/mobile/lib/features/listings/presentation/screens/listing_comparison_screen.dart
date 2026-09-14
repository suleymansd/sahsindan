import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/listing_photo.dart';
import '../../../../shared/widgets/listing_spec.dart';
import '../providers/comparison_provider.dart';

class ListingComparisonScreen extends ConsumerWidget {
  const ListingComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(comparisonProvider);
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Araç Karşılaştırma')),
      body: listings.isEmpty
          ? AppEmptyState(
              title: 'Karşılaştırmak için ilan seçin',
              description:
                  'Arama sonuçlarından en fazla 3 araç ekleyebilirsiniz.',
              icon: Icons.compare_arrows_rounded,
              secondaryLabel: 'İlanları keşfet',
              onSecondary: () => context.go('/app/listings'),
            )
          : SafeArea(
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yan yana, tüm detaylarıyla.',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    const Text(
                        'Fiyat, kilometre ve satıcı güven skorunu karşılaştırın. Bilgiler seçtiğiniz ilanlardan alınır.',
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.5)),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: listings
                                .map((listing) => Container(
                                      width: 220,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: AppColors.separator),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: AspectRatio(
                                                    aspectRatio: 4 / 3,
                                                    child: ListingPhotoView(
                                                        url: listing
                                                                .photos.isEmpty
                                                            ? null
                                                            : resolvePublicUrl(
                                                                publicBaseUrl:
                                                                    config
                                                                        .publicBaseUrl,
                                                                maybeRelative:
                                                                    listing
                                                                        .photos
                                                                        .first
                                                                        .url)))),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                                height: 48,
                                                child: Text(listing.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium)),
                                            for (final spec in <String, String>{
                                              'Fiyat':
                                                  '${listingNumber(listing.price)} TL',
                                              'Model yılı':
                                                  '${listing.carDetails.year}',
                                              'Kilometre':
                                                  '${listingNumber(listing.carDetails.mileage)} km',
                                              'Yakıt': carLabel(
                                                  listing.carDetails.fuel),
                                              'Şanzıman': carLabel(listing
                                                  .carDetails.transmission),
                                              'Güven skoru':
                                                  '${listing.owner.trustScore} / 100',
                                              'Konum': listing.district,
                                            }.entries)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8),
                                                  child: ListingSpec(
                                                      label: spec.key,
                                                      value: spec.value)),
                                            OutlinedButton(
                                                onPressed: () => context.push(
                                                    '/app/listings/${listing.id}'),
                                                child:
                                                    const Text('İlanı incele')),
                                            TextButton(
                                                onPressed: () => ref
                                                    .read(comparisonProvider
                                                        .notifier)
                                                    .toggle(listing),
                                                child: const Text(
                                                    'Karşılaştırmadan çıkar')),
                                          ]),
                                    ))
                                .toList())),
                  ]),
            )),
    );
  }
}
