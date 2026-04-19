import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'access_token_store.dart';

class TokenStore implements AccessTokenStore {
  TokenStore(this._storage);

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  @override
  Future<void> writeAccessToken(String token) => _storage.write(key: _kAccessToken, value: token);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  @override
  Future<void> writeRefreshToken(String token) => _storage.write(key: _kRefreshToken, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }
}
