import 'dart:async';

import 'package:dio/dio.dart';

import '../session_invalidator.dart';
import '../access_token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AccessTokenStore tokenStore,
    required Dio clientDio,
    required Dio refreshDio,
    required SessionInvalidator invalidator,
  }) :
        // Keep the public named arguments and private fields (Dart 3.3 API).
        // ignore: prefer_initializing_formals
        _tokenStore = tokenStore,
        // ignore: prefer_initializing_formals
        _clientDio = clientDio,
        // ignore: prefer_initializing_formals
        _refreshDio = refreshDio,
        // ignore: prefer_initializing_formals
        _invalidator = invalidator;

  final AccessTokenStore _tokenStore;
  final Dio _clientDio;
  final Dio _refreshDio;
  final SessionInvalidator _invalidator;

  Future<String?>? _refreshing;

  bool _isPublicAuth(String path) => const {
        '/auth/login', '/auth/register', '/auth/refresh', '/auth/logout',
        '/auth/forgot-password', '/auth/reset-password',
      }.contains(path);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['X-Client'] = 'mobile';

    // Avoid adding Authorization to auth endpoints.
    if (!_isPublicAuth(options.path)) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    if (status == 401 && req.extra['retried'] != true && !_isPublicAuth(req.path)) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken == null) {
          _invalidator.invalidate();
          return handler.next(err);
        }

        final retry = await _retry(req, newToken);
        return handler.resolve(retry);
      } on DioException catch (refreshError) {
        if (refreshError.response?.statusCode == 401 || refreshError.response?.statusCode == 403) {
          _invalidator.invalidate();
        }
        return handler.next(err);
      } catch (_) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  Future<String?> _refreshAccessToken() {
    _refreshing ??= () async {
      try {
        final refreshToken = await _tokenStore.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) return null;

        final res = await _refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'X-Client': 'mobile'}),
        );
        final data = res.data;
        if (data is! Map<String, dynamic>) return null;
        final inner = data['data'];
        if (inner is! Map<String, dynamic>) return null;
        final access = inner['access_token'] as String?;
        if (access == null || access.isEmpty) return null;
        await _tokenStore.writeAccessToken(access);
        final newRefresh = inner['refresh_token'] as String?;
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _tokenStore.writeRefreshToken(newRefresh);
        }
        return access;
      } finally {
        // Allow next refresh attempt.
        _refreshing = null;
      }
    }();

    return _refreshing!;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions, String token) async {
    final cloned = requestOptions.copyWith(
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
      extra: {
        ...requestOptions.extra,
        'retried': true,
      },
    );

    return _clientDio.fetch<dynamic>(cloned);
  }
}
