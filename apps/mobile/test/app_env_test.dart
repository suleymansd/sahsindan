import 'package:flutter_test/flutter_test.dart';
import 'package:trustmarket_mobile/core/config/app_env.dart';

void main() {
  test('Release API requires HTTPS and the API route prefix', () {
    for (final value in [
      '', 'http://app.test/api', 'https://app.test',
      'https://app.test/api?token=secret', 'https://app.test/api#fragment',
      'https://user:secret@app.test/api', 'not a url',
    ]) {
      expect(() => AppEnv.validateApiBaseUrl(value, release: true),
          throwsStateError, reason: value);
    }
  });

  test('Release normalizes a valid API URL', () {
    expect(AppEnv.validateApiBaseUrl('https://app.test/api/', release: true),
        'https://app.test/api');
  });

  test('Debug still supports the local API', () {
    expect(AppEnv.validateApiBaseUrl('http://localhost:8080/api', release: false),
        'http://localhost:8080/api');
  });
}
