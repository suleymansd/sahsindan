import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:trustmarket_mobile/core/network/in_memory_token_store.dart';
import 'package:trustmarket_mobile/features/auth/data/auth_repository.dart';

void main() {
  test('AuthRepository.login parses envelope and stores access token', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    final store = InMemoryTokenStore();

    // Clean before test.
    await store.clear();

    adapter.onPost(
      '/auth/login',
      (server) => server.reply(
        200,
        {
          'data': {
            'access_token': 'ACCESS',
            'refresh_token': 'REFRESH',
            'user': {
              'id': 1,
              'email': 'u@x.com',
              'phone': '555',
              'role': 'USER_VERIFIED',
              'status': 'ACTIVE',
              'trust_score': 50,
            }
          },
          'meta': {}
        },
      ),
      data: {'email': 'u@x.com', 'password': 'pass'},
    );

    final repo = AuthRepository(dio: dio, tokenStore: store);
    final user = await repo.login(email: 'u@x.com', password: 'pass');

    expect(user.email, 'u@x.com');
    expect(user.trustScore, 50);

    final saved = await store.readAccessToken();
    expect(saved, 'ACCESS');
  });
}
