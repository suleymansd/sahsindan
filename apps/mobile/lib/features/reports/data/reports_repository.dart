import 'package:dio/dio.dart';

import '../../../shared/models/api_envelope.dart';

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  Future<int> createReport({
    required int listingId,
    required String reason,
    String? category,
  }) async {
    final res = await _dio.post(
      '/reports',
      data: {
        'listing_id': listingId,
        'reason': reason,
        'category': category,
      },
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => obj as Map<String, dynamic>);
    return env.data['report_id'] as int;
  }
}
