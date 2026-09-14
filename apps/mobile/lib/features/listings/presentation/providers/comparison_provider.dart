import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/listing.dart';

final comparisonProvider =
    StateNotifierProvider<ComparisonController, List<Listing>>(
        (ref) => ComparisonController());

class ComparisonController extends StateNotifier<List<Listing>> {
  ComparisonController() : super(const []);

  bool toggle(Listing listing) {
    if (state.any((item) => item.id == listing.id)) {
      state = state.where((item) => item.id != listing.id).toList();
      return true;
    }
    if (state.length >= 3) return false;
    state = [...state, listing];
    return true;
  }
}
