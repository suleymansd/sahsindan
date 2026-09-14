import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_keys.dart';

class AppEnv {
  static String get apiBaseUrl {
    // Highest priority: --dart-define=API_BASE_URL=...
    const defineValue = String.fromEnvironment(EnvKeys.apiBaseUrl, defaultValue: '');
    if (defineValue.trim().isNotEmpty) return _validatedUrl(defineValue.trim());

    // Next: .env asset
    try {
      final envValue = dotenv.env[EnvKeys.apiBaseUrl];
      if (envValue != null && envValue.trim().isNotEmpty) return _validatedUrl(envValue.trim());
    } catch (_) {
      // dotenv may not be initialized in tests; fall back below.
    }

    if (kReleaseMode) {
      throw StateError("Release builds require API_BASE_URL=https://your-domain/api");
    }

    // Fallback: platform-based localhost resolution.
    // Android emulator cannot reach host machine on 127.0.0.1; use 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    }
    // Both the direct FastAPI server and Nginx expose routes under /api.
    return 'http://localhost:8080/api';
  }

  static String _validatedUrl(String value) {
    final uri = Uri.tryParse(value);
    if (kReleaseMode && (uri == null || uri.scheme != "https" || uri.host.isEmpty)) {
      throw StateError("Release API_BASE_URL must use HTTPS");
    }
    return value;
  }

  static bool get logNetwork {
    if (kReleaseMode) return false;
    const defineValue = String.fromEnvironment(EnvKeys.logNetwork, defaultValue: '');
    if (defineValue.trim().isNotEmpty) {
      return defineValue.toLowerCase().trim() == 'true';
    }
    try {
      final envValue = dotenv.env[EnvKeys.logNetwork];
      if (envValue == null) return !kReleaseMode;
      return envValue.toLowerCase().trim() == 'true';
    } catch (_) {
      return !kReleaseMode;
    }
  }
}
