import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../config/app_env.dart';
import 'dio_factory.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'session_invalidator.dart';
import 'token_store.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnv();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final dioRefreshProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);

  return buildDio(
    baseUrl: cfg.apiBaseUrl,
    interceptors: [
      NetworkLoggingInterceptor(enabled: AppEnv.logNetwork),
    ],
  );
});

final dioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  final store = ref.watch(tokenStoreProvider);
  final refreshDio = ref.watch(dioRefreshProvider);
  final invalidator = ref.watch(sessionInvalidatorProvider.notifier);

  // Create client first, then attach interceptors that may need the client reference.
  final client = buildDio(baseUrl: cfg.apiBaseUrl, interceptors: const []);

  client.interceptors.add(NetworkLoggingInterceptor(enabled: AppEnv.logNetwork));
  client.interceptors.add(
    AuthInterceptor(
      tokenStore: store,
      clientDio: client,
      refreshDio: refreshDio,
      invalidator: invalidator,
    ),
  );

  return client;
});
