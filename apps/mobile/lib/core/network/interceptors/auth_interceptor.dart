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
  })  : _tokenStore = tokenStore,
        _clientDio = clientDio,
        _refreshDio = refreshDio,
        _invalidator = invalidator;

  final AccessTokenStore _tokenStore;
  final Dio _clientDio;
  final Dio _refreshDio;
  final SessionInvalidator _invalidator;

  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['X-Client'] = 'mobile';

    // Avoid adding Authorization to auth endpoints.
    if (!options.path.startsWith('/auth/')) {
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

    if (status == 401 && req.extra['retried'] != true && !req.path.startsWith('/auth/')) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken == null) {
          _invalidator.invalidate();
          return handler.next(err);
        }

        final retry = await _retry(req, newToken);
        return handler.resolve(retry);
      } catch (_) {
        _invalidator.invalidate();
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
          queryParameters: {'refresh_token': refreshToken},
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
