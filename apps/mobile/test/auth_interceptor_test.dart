import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:trustmarket_mobile/core/network/in_memory_token_store.dart';
import 'package:trustmarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:trustmarket_mobile/core/network/session_invalidator.dart';

class ExpiringAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    return ResponseBody.fromString('{"data":{}}', calls++ == 0 ? 401 : 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late Dio refreshDio;
  late DioAdapter adapter;
  late DioAdapter refreshAdapter;
  late InMemoryTokenStore store;
  late SessionInvalidator invalidator;
  late List<String?> sentTokens;

  setUp(() async {
    dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    refreshDio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    adapter = DioAdapter(dio: dio);
    refreshAdapter = DioAdapter(dio: refreshDio);
    store = InMemoryTokenStore();
    await store.writeAccessToken('OLD');
    await store.writeRefreshToken('REFRESH');
    invalidator = SessionInvalidator();
    sentTokens = [];
    dio.interceptors.add(AuthInterceptor(tokenStore: store, clientDio: dio,
        refreshDio: refreshDio, invalidator: invalidator));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      sentTokens.add(options.headers['Authorization'] as String?);
      handler.next(options);
    }));
  });

  tearDown(() {
    dio.close();
    refreshDio.close();
    invalidator.dispose();
  });

  test('/auth/me includes access token', () async {
    adapter.onGet('/auth/me', (server) => server.reply(200, {'data': {}}));
    await dio.get('/auth/me');
    expect(sentTokens, ['Bearer OLD']);
  });

  test('expired /auth/me refreshes and retries once', () async {
    dio.httpClientAdapter = ExpiringAdapter();
    refreshAdapter.onPost('/auth/refresh', (server) => server.reply(200, {
      'data': {'access_token': 'NEW', 'refresh_token': 'ROTATED'}
    }), data: {'refresh_token': 'REFRESH'});
    final response = await dio.get('/auth/me');
    expect(response.statusCode, 200);
    expect(sentTokens, ['Bearer OLD', 'Bearer NEW']);
    expect(await store.readRefreshToken(), 'ROTATED');
  });

  test('wrong login password never triggers refresh', () async {
    adapter.onPost('/auth/login', (server) => server.reply(401, {}));
    await expectLater(dio.post('/auth/login'), throwsA(isA<DioException>()));
    expect(sentTokens, [null]);
    expect(await store.readAccessToken(), 'OLD');
  });

  test('temporary refresh failure does not log the user out', () async {
    var invalidations = 0;
    invalidator.addListener((_) => invalidations++, fireImmediately: false);
    adapter.onGet('/auth/me', (server) => server.reply(401, {}));
    refreshAdapter.onPost('/auth/refresh', (server) => server.reply(503, {}),
        data: {'refresh_token': 'REFRESH'});
    await expectLater(dio.get('/auth/me'), throwsA(isA<DioException>()));
    expect(invalidations, 0);
  });
}
