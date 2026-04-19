import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/verification.dart';

class VerificationRepository {
  VerificationRepository(this._dio);

  final Dio _dio;

  Future<VerificationStatus> getStatus() async {
    final res = await _dio.get('/verification/status');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => VerificationStatus.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<int> submit({
    required String phoneOtp,
    required bool backgroundConsent,
    required bool professionProof,
  }) async {
    final res = await _dio.post(
      '/verification/submit',
      data: {
        'phone_otp': phoneOtp,
        'selfie_passed': true,
        'profession_proof': professionProof ? 'uploaded' : null,
        'background_consent': backgroundConsent,
      },
    );

    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => obj as Map<String, dynamic>);
    return env.data['request_id'] as int;
  }

  Future<void> uploadAsset({
    required int requestId,
    required String type,
    required String filename,
    required List<int> bytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: MediaType.parse(contentType)),
    });

    await _dio.post(
      '/verification/assets/upload',
      queryParameters: {
        'request_id': requestId,
        'type': type,
      },
      data: form,
      onSendProgress: onProgress,
    );
  }
}
