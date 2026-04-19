import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_keys.dart';

class AppEnv {
  static String get apiBaseUrl {
    // Highest priority: --dart-define=API_BASE_URL=...
    const defineValue = String.fromEnvironment(EnvKeys.apiBaseUrl, defaultValue: '');
    if (defineValue.trim().isNotEmpty) return defineValue.trim();

    // Next: .env asset
    try {
      final envValue = dotenv.env[EnvKeys.apiBaseUrl];
      if (envValue != null && envValue.trim().isNotEmpty) return envValue.trim();
    } catch (_) {
      // dotenv may not be initialized in tests; fall back below.
    }

    // Fallback: platform-based localhost resolution.
    // Android emulator cannot reach host machine on 127.0.0.1; use 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    // Docker-free dev_local.sh runs the API directly on :8080 (no /api prefix).
    // If you run via Nginx (infra), set API_BASE_URL=http://localhost:8080/api in .env or --dart-define.
    return 'http://localhost:8080';
  }

  static bool get logNetwork {
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
