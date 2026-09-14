import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/listing.dart';
import '../../data/listings_repository.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(dioProvider));
});

const _unchanged = Object();

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
    this.offset = 0,
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
  final int offset;

  ListingsQuery copyWith({
    Object? q = _unchanged,
    Object? city = _unchanged,
    Object? district = _unchanged,
    Object? brand = _unchanged,
    Object? model = _unchanged,
    Object? transmission = _unchanged,
    Object? fuel = _unchanged,
    Object? color = _unchanged,
    Object? minPrice = _unchanged,
    Object? maxPrice = _unchanged,
    Object? yearMin = _unchanged,
    Object? yearMax = _unchanged,
    Object? mileageMin = _unchanged,
    Object? mileageMax = _unchanged,
    bool? needsConfirmationOnly,
    String? sort,
    int? offset,
  }) {
    return ListingsQuery(
      q: identical(q, _unchanged) ? this.q : q as String?,
      city: identical(city, _unchanged) ? this.city : city as String?,
      district:
          identical(district, _unchanged) ? this.district : district as String?,
      brand: identical(brand, _unchanged) ? this.brand : brand as String?,
      model: identical(model, _unchanged) ? this.model : model as String?,
      transmission: identical(transmission, _unchanged)
          ? this.transmission
          : transmission as String?,
      fuel: identical(fuel, _unchanged) ? this.fuel : fuel as String?,
      color: identical(color, _unchanged) ? this.color : color as String?,
      minPrice:
          identical(minPrice, _unchanged) ? this.minPrice : minPrice as double?,
      maxPrice:
          identical(maxPrice, _unchanged) ? this.maxPrice : maxPrice as double?,
      yearMin: identical(yearMin, _unchanged) ? this.yearMin : yearMin as int?,
      yearMax: identical(yearMax, _unchanged) ? this.yearMax : yearMax as int?,
      mileageMin: identical(mileageMin, _unchanged)
          ? this.mileageMin
          : mileageMin as int?,
      mileageMax: identical(mileageMax, _unchanged)
          ? this.mileageMax
          : mileageMax as int?,
      needsConfirmationOnly:
          needsConfirmationOnly ?? this.needsConfirmationOnly,
      sort: sort ?? this.sort,
      offset: offset ?? 0,
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
    offset: q.offset,
  );
  if (!q.needsConfirmationOnly) return items;
  return items.where((e) => e.staleState == 'NEEDS_CONFIRMATION').toList();
});

final favoritesOffsetProvider = StateProvider.autoDispose<int>((ref) => 0);

final favoritesProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  return ref.watch(listingsRepositoryProvider).favorites(offset: ref.watch(favoritesOffsetProvider));
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
  final items = await ref
      .watch(listingsRepositoryProvider)
      .mine(includeInactive: q.includeInactive);
  if (q.state == null) return items;
  return items.where((e) => e.state == q.state).toList();
});

final listingDetailProvider =
    FutureProvider.family<Listing, int>((ref, id) async {
  return ref.watch(listingsRepositoryProvider).get(id);
});
