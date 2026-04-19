import 'app_error.dart';
import 'error_mapper.dart';

AppError toAppError(Object e) => ErrorMapper.fromDio(e);

String friendlyErrorText(Object e) {
  final err = ErrorMapper.fromDio(e);
  final text = err.when(
    network: (m) => m,
    unauthorized: () => 'Oturum suresi doldu. Lutfen tekrar giris yapin.',
    forbidden: (m) => m ?? 'Bu islem icin yetkiniz yok.',
    rateLimited: (m) => m ?? 'Cok fazla istek. Biraz yavaslayin.',
    validation: (m, _) => m ?? 'Gecersiz veri.',
    server: (m) => m,
    unknown: (m) => m,
  );

  // As a last-resort guard: don't show giant DioException dumps to the user.
  final lower = text.toLowerCase();
  if (lower.contains('dioexception') || lower.contains('requestoptions.validatestatus') || lower.contains('developer.mozilla.org')) {
    return 'Islem basarisiz. Lutfen tekrar deneyin.';
  }
  return text;
}

bool isForbiddenError(Object e) {
  final err = ErrorMapper.fromDio(e);
  return err.maybeWhen(forbidden: (_) => true, orElse: () => false);
}
