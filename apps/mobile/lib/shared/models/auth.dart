// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

@freezed
class AuthPayload with _$AuthPayload {
  const factory AuthPayload({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    required UserSummary user,
  }) = _AuthPayload;

  factory AuthPayload.fromJson(Map<String, dynamic> json) => _$AuthPayloadFromJson(json);
}

@freezed
class RefreshPayload with _$RefreshPayload {
  const factory RefreshPayload({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') String? refreshToken,
  }) = _RefreshPayload;

  factory RefreshPayload.fromJson(Map<String, dynamic> json) => _$RefreshPayloadFromJson(json);
}
