import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/listing.dart';
import '../../data/listings_repository.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(dioProvider));
});

class ListingsQuery {
  ListingsQuery({
    this.q,
    this.city,
    this.district,
    this.brand,
    this.model,
    this.transmission,
    this.fuel,
    this.color,
    this.minPrice,
    this.maxPrice,
    this.yearMin,
    this.yearMax,
    this.mileageMin,
    this.mileageMax,
    this.needsConfirmationOnly = false,
    this.sort = 'newest',
  });

  final String? q;
  final String? city;
  final String? district;
  final String? brand;
  final String? model;
  final String? transmission;
  final String? fuel;
  final String? color;
  final double? minPrice;
  final double? maxPrice;
  final int? yearMin;
  final int? yearMax;
  final int? mileageMin;
  final int? mileageMax;
  final bool needsConfirmationOnly;
  final String sort;

  ListingsQuery copyWith({
    String? q,
    String? city,
    String? district,
    String? brand,
    String? model,
    String? transmission,
    String? fuel,
    String? color,
    double? minPrice,
    double? maxPrice,
    int? yearMin,
    int? yearMax,
    int? mileageMin,
    int? mileageMax,
    bool? needsConfirmationOnly,
    String? sort,
  }) {
    return ListingsQuery(
      q: q ?? this.q,
      city: city ?? this.city,
      district: district ?? this.district,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      color: color ?? this.color,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      yearMin: yearMin ?? this.yearMin,
      yearMax: yearMax ?? this.yearMax,
      mileageMin: mileageMin ?? this.mileageMin,
      mileageMax: mileageMax ?? this.mileageMax,
      needsConfirmationOnly: needsConfirmationOnly ?? this.needsConfirmationOnly,
      sort: sort ?? this.sort,
    );
  }
}

final listingsQueryProvider = StateProvider<ListingsQuery>((ref) {
  return ListingsQuery(city: 'ISTANBUL');
});

final listingsProvider = FutureProvider<List<Listing>>((ref) async {
  final repo = ref.watch(listingsRepositoryProvider);
  final q = ref.watch(listingsQueryProvider);
  final items = await repo.list(
    q: q.q,
    city: q.city,
    district: q.district,
    brand: q.brand,
    model: q.model,
    transmission: q.transmission,
    fuel: q.fuel,
    color: q.color,
    minPrice: q.minPrice,
    maxPrice: q.maxPrice,
    yearMin: q.yearMin,
    yearMax: q.yearMax,
    mileageMin: q.mileageMin,
    mileageMax: q.mileageMax,
    sort: q.sort,
  );
  if (!q.needsConfirmationOnly) return items;
  return items.where((e) => e.staleState == 'NEEDS_CONFIRMATION').toList();
});

final favoritesProvider = FutureProvider<List<Listing>>((ref) async {
  return ref.watch(listingsRepositoryProvider).favorites();
});

class MyListingsQuery {
  const MyListingsQuery({
    required this.includeInactive,
    this.state,
  });

  final bool includeInactive;
  final String? state;

  MyListingsQuery copyWith({
    bool? includeInactive,
    String? state,
  }) {
    return MyListingsQuery(
      includeInactive: includeInactive ?? this.includeInactive,
      state: state,
    );
  }
}

final myListingsQueryProvider = StateProvider<MyListingsQuery>((ref) {
  return const MyListingsQuery(includeInactive: true);
});

final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final q = ref.watch(myListingsQueryProvider);
  final items = await ref.watch(listingsRepositoryProvider).mine(includeInactive: q.includeInactive);
  if (q.state == null) return items;
  return items.where((e) => e.state == q.state).toList();
});

final listingDetailProvider = FutureProvider.family<Listing, int>((ref, id) async {
  return ref.watch(listingsRepositoryProvider).get(id);
});
