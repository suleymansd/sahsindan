import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'listings_providers.dart';

class FavoritesState {
  const FavoritesState({
    required this.ids,
    required this.loading,
  });

  final Set<int> ids;
  final bool loading;

  FavoritesState copyWith({Set<int>? ids, bool? loading}) {
    return FavoritesState(
      ids: ids ?? this.ids,
      loading: loading ?? this.loading,
    );
  }
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._ref) : super(const FavoritesState(ids: <int>{}, loading: false));

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    try {
      final items = await _ref.read(listingsRepositoryProvider).favorites();
      state = FavoritesState(ids: items.map((e) => e.id).toSet(), loading: false);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  bool isFavorited(int id) => state.ids.contains(id);

  Future<void> toggle(int listingId) async {
    final was = state.ids.contains(listingId);

    // optimistic
    final next = {...state.ids};
    if (was) {
      next.remove(listingId);
    } else {
      next.add(listingId);
    }
    state = state.copyWith(ids: next);

    try {
      if (was) {
        await _ref.read(listingsRepositoryProvider).unfavorite(listingId);
      } else {
        await _ref.read(listingsRepositoryProvider).favorite(listingId);
      }

      _ref.invalidate(favoritesProvider);
    } catch (_) {
      // rollback
      final rollback = {...state.ids};
      if (was) {
        rollback.add(listingId);
      } else {
        rollback.remove(listingId);
      }
      state = state.copyWith(ids: rollback);
      rethrow;
    }
  }
}

final favoritesControllerProvider = StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final c = FavoritesController(ref);
  // warm
  Future.microtask(() => c.refresh());
  return c;
});
