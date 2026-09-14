import 'package:dio/dio.dart';

import '../../../shared/models/api_envelope.dart';
import '../../../shared/models/auth.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/verification.dart';
import '../../../core/network/access_token_store.dart';

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required AccessTokenStore tokenStore,
  }) :
        // Keep the public named arguments and private fields (Dart 3.3 API).
        // ignore: prefer_initializing_formals
        _dio = dio,
        // ignore: prefer_initializing_formals
        _tokenStore = tokenStore;

  final Dio _dio;
  final AccessTokenStore _tokenStore;

  Future<UserSummary> me() async {
    final res = await _dio.get('/auth/me');
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => UserSummary.fromJson(obj as Map<String, dynamic>));
    return env.data;
  }

  Future<VerificationStatus> verificationStatus() async {
    final res = await _dio.get('/verification/status');
    final env = ApiEnvelope.fromJson(
      res.data as Map<String, dynamic>,
      (obj) => VerificationStatus.fromJson(obj as Map<String, dynamic>),
    );
    return env.data;
  }

  Future<UserSummary> login({required String email, required String password, String? otpCode}) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password, if (otpCode != null && otpCode.isNotEmpty) 'otp_code': otpCode},
      options: Options(headers: {'X-Client': 'mobile'}),
    );
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => AuthPayload.fromJson(obj as Map<String, dynamic>));
    await _tokenStore.writeAccessToken(env.data.accessToken);
    if (env.data.refreshToken != null) {
      await _tokenStore.writeRefreshToken(env.data.refreshToken!);
    }
    return env.data.user;
  }

  Future<UserSummary> register({
    required String email,
    required String phone,
    required String password,
    required String name,
    required String city,
    String? professionCategory,
  }) async {
    final res = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'phone': phone,
        'password': password,
        'name': name,
        'city': city,
        'profession_category': professionCategory,
      },
      options: Options(headers: {'X-Client': 'mobile'}),
    );
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => AuthPayload.fromJson(obj as Map<String, dynamic>));
    await _tokenStore.writeAccessToken(env.data.accessToken);
    if (env.data.refreshToken != null) {
      await _tokenStore.writeRefreshToken(env.data.refreshToken!);
    }
    return env.data.user;
  }

  Future<String?> refresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Missing refresh token');
    }

    final res = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'X-Client': 'mobile'}),
    );
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => RefreshPayload.fromJson(obj as Map<String, dynamic>));
    await _tokenStore.writeAccessToken(env.data.accessToken);
    if (env.data.refreshToken != null) {
      await _tokenStore.writeRefreshToken(env.data.refreshToken!);
    }
    return env.data.accessToken;
  }

  Future<String?> forgotPassword({required String email}) async {
    final res = await _dio.post('/auth/forgot-password', data: {'email': email});
    final env = ApiEnvelope.fromJson(res.data as Map<String, dynamic>, (obj) => (obj as Map<String, dynamic>));
    return env.data['reset_token'] as String?;
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _dio.post('/auth/reset-password', data: {'token': token, 'new_password': newPassword});
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStore.readRefreshToken();
      await _dio.post(
        '/auth/logout',
        data: refreshToken != null ? {'refresh_token': refreshToken} : null,
        options: Options(headers: {'X-Client': 'mobile'}),
      );
    } catch (_) {
      // ignore network failures on logout
    }
    await _tokenStore.clear();
  }
}
