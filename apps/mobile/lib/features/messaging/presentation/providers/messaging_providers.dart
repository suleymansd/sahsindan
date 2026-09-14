import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/thread.dart';
import '../../data/messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioProvider));
});

final threadsProvider = FutureProvider<List<Thread>>((ref) async {
  return ref.watch(messagingRepositoryProvider).listThreads();
});

final threadBeforeProvider = StateProvider.autoDispose.family<int?, int>((ref, id) => null);

final threadProvider = FutureProvider.autoDispose.family<Thread, int>((ref, id) async {
  return ref.watch(messagingRepositoryProvider).getThread(id, beforeId: ref.watch(threadBeforeProvider(id)));
});
