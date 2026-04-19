import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/trust_breakdown.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final trustBreakdownProvider = FutureProvider<TrustBreakdown>((ref) async {
  return ref.watch(profileRepositoryProvider).trust();
});
