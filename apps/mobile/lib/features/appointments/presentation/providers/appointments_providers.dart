import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/appointment.dart';
import '../../data/appointments_repository.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(dioProvider));
});

final appointmentsOffsetProvider = StateProvider.autoDispose<int>((ref) => 0);

final appointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((ref) async {
  return ref.watch(appointmentsRepositoryProvider).inbox(offset: ref.watch(appointmentsOffsetProvider));
});
