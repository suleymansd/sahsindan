import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class NetworkLoggingInterceptor extends Interceptor {
  NetworkLoggingInterceptor({required this.enabled});

  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '-> ${options.method} ${options.uri}',
        name: 'net',
        error: options.data is FormData ? 'FormData' : options.data,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        '<- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
        name: 'net',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      developer.log(
        'xx ${err.response?.statusCode} ${err.requestOptions.method} ${err.requestOptions.uri}',
        name: 'net',
        error: err,
      );
    }
    handler.next(err);
  }
}
