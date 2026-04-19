import 'package:dio/dio.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/trust_breakdown.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<TrustBreakdown> trust() async {
    final res = await _dio.get('/profile/trust');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => TrustBreakdown.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }
}
