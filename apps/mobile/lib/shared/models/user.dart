// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class UserSummary with _$UserSummary {
  const factory UserSummary({
    required int id,
    required String email,
    required String phone,
    required String role,
    required String status,
    @JsonKey(name: 'trust_score') required int trustScore,
  }) = _UserSummary;

  factory UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);
}

extension UserSummaryX on UserSummary {
  bool get isPending => role == 'USER_PENDING';
  bool get isVerified => role == 'USER_VERIFIED' || isAdmin;
  bool get isAdmin => role == 'ADMIN' || role == 'MODERATOR';
  bool get isBanned => role == 'BANNED' || status == 'SUSPENDED';
}
