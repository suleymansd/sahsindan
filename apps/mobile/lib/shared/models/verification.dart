// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

@freezed
class VerificationStatus with _$VerificationStatus {
  const factory VerificationStatus({
    required String status,
    String? reason,
    @JsonKey(name: 'reason_code') String? reasonCode,
  }) = _VerificationStatus;

  factory VerificationStatus.fromJson(Map<String, dynamic> json) => _$VerificationStatusFromJson(json);
}
