import 'package:dio/dio.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/thread.dart';

class MessagingRepository {
  MessagingRepository(this._dio);

  final Dio _dio;

  Future<List<Thread>> listThreads() async {
    final res = await _dio.get('/threads');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) {
      return (obj as List<dynamic>).map((e) => Thread.fromJson(e as Map<String, dynamic>)).toList();
    });
    return env.data;
  }

  Future<Thread> getThread(int id) async {
    final res = await _dio.get('/threads/$id');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Thread.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<Thread> createThread({required int listingId}) async {
    final res = await _dio.post('/threads', data: {'listing_id': listingId});
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => Thread.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<void> sendMessage({required int threadId, required String body}) async {
    await _dio.post('/threads/$threadId/messages', data: {'body': body});
  }

  Future<void> markRead({required int threadId}) async {
    await _dio.post('/threads/$threadId/read');
  }
}
