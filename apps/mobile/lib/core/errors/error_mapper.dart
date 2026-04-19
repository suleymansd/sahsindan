import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/api_envelope.dart';
import 'app_error.dart';

class ErrorMapper {
  static AppError fromDio(Object error) {
    if (error is! DioException) {
      return AppError.unknown(message: error.toString());
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const AppError.network(
        message: 'Sunucuya ulasilamiyor. Baglantinizi kontrol edin. (API calisiyor mu?)',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      // On web this is often "XMLHttpRequest error" when API is down or CORS blocks the request.
      const extra = kIsWeb ? ' APIyi baslat: services/api/scripts/dev_local.sh' : '';
      return const AppError.network(message: 'Baglanti hatasi. Lutfen tekrar deneyin.$extra');
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;

    ApiErrorResponse? apiErr;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      try {
        apiErr = ApiErrorEnvelope.fromJson(data).error;
      } catch (_) {
        // ignore parsing errors
      }
    }

    if (status == 401) return const AppError.unauthorized();
    if (status == 403) return AppError.forbidden(message: apiErr?.message);
    if (status == 429 || apiErr?.code == 'RATE_LIMITED') {
      return AppError.rateLimited(message: apiErr?.message ?? 'Cok fazla istek. Biraz yavaslayin.');
    }

    if (status == 422 || apiErr?.code == 'VALIDATION_ERROR') {
      return AppError.validation(message: apiErr?.message ?? 'Gecersiz veri.', details: apiErr?.details);
    }

    if (status != null && status >= 500) {
      return AppError.server(message: apiErr?.message ?? 'Sunucu hatasi.');
    }

    if (apiErr != null) {
      return AppError.unknown(message: apiErr.message);
    }

    return AppError.unknown(message: error.message ?? 'Bilinmeyen hata');
  }
}
