import 'access_token_store.dart';

class InMemoryTokenStore implements AccessTokenStore {
  String? _token;
  String? _refresh;

  @override
  Future<void> clear() async {
    _token = null;
    _refresh = null;
  }

  @override
  Future<String?> readAccessToken() async {
    return _token;
  }

  @override
  Future<void> writeAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> readRefreshToken() async {
    return _refresh;
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    _refresh = token;
  }
}
