import 'package:flutter/foundation.dart';

String resolvePublicUrl({required String publicBaseUrl, required String maybeRelative}) {
  if (maybeRelative.trim().isEmpty) return maybeRelative;
  if (maybeRelative.startsWith('http://') || maybeRelative.startsWith('https://')) {
    return maybeRelative;
  }

  // For web builds, relative paths can resolve against current origin.
  if (kIsWeb) return maybeRelative;

  final base = publicBaseUrl.endsWith('/') ? publicBaseUrl.substring(0, publicBaseUrl.length - 1) : publicBaseUrl;
  final path = maybeRelative.startsWith('/') ? maybeRelative : '/$maybeRelative';
  return '$base$path';
}
