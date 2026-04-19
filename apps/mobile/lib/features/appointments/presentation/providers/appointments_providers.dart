import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../shared/models/appointment.dart';
import '../../data/appointments_repository.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(dioProvider));
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return ref.watch(appointmentsRepositoryProvider).inbox();
});
