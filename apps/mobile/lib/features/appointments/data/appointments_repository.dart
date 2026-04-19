import 'package:dio/dio.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/appointment.dart';

class AppointmentsRepository {
  AppointmentsRepository(this._dio);

  final Dio _dio;

  Future<List<Appointment>> inbox() async {
    final res = await _dio.get('/appointments/inbox');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) {
      return (obj as List<dynamic>).map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
    });
    return env.data;
  }

  Future<Appointment> create({
    required int listingId,
    required DateTime scheduledAt,
    required String location,
    String? notes,
  }) async {
    final res = await _dio.post('/appointments', data: {
      'listing_id': listingId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'location': location,
      'notes': notes,
    });
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> accept(int id) async {
    final res = await _dio.post('/appointments/$id/accept');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> decline(int id) async {
    final res = await _dio.post('/appointments/$id/decline');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> cancel(int id) async {
    final res = await _dio.post('/appointments/$id/cancel');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> complete(int id) async {
    final res = await _dio.post('/appointments/$id/complete');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> noShow(int id) async {
    final res = await _dio.post('/appointments/$id/no-show');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Appointment> reschedule(int id, DateTime scheduledAt) async {
    final res = await _dio.post('/appointments/$id/reschedule', queryParameters: {'scheduled_at': scheduledAt.toIso8601String()});
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Appointment.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<void> rate(int id, int rating) async {
    await _dio.post('/appointments/$id/rate', queryParameters: {'rating': rating});
  }
}
