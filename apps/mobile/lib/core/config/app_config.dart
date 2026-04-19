import 'package:collection/collection.dart';

import 'app_env.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.publicBaseUrl});

  final String apiBaseUrl;
  final String publicBaseUrl;

  static AppConfig fromEnv() {
    final api = AppEnv.apiBaseUrl;
    final uri = Uri.parse(api);

    // Expect apiBaseUrl like http(s)://host:port/api
    // Derive publicBaseUrl as http(s)://host:port
    final segments = [...uri.pathSegments];
    if (segments.isNotEmpty && segments.last.isEmpty) {
      segments.removeLast();
    }
    final withoutApi = segments.lastOrNull == 'api' ? segments.take(segments.length - 1).toList() : segments;

    final publicUri = uri.replace(pathSegments: withoutApi);

    return AppConfig(
      apiBaseUrl: uri.toString().replaceAll(RegExp(r'/*$'), ''),
      publicBaseUrl: publicUri.toString().replaceAll(RegExp(r'/*$'), ''),
    );
  }
}
