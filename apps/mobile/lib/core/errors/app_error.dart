import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const factory AppError.network({required String message}) = _NetworkError;
  const factory AppError.unauthorized() = _UnauthorizedError;
  const factory AppError.forbidden({String? message}) = _ForbiddenError;
  const factory AppError.rateLimited({String? message}) = _RateLimitedError;
  const factory AppError.validation({String? message, Map<String, dynamic>? details}) = _ValidationError;
  const factory AppError.server({required String message}) = _ServerError;
  const factory AppError.unknown({required String message}) = _UnknownError;
}
