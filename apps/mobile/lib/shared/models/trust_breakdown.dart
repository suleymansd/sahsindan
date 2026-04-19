// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'trust_breakdown.freezed.dart';
part 'trust_breakdown.g.dart';

@freezed
class TrustBreakdown with _$TrustBreakdown {
  const factory TrustBreakdown({
    @Default(0) int total,
    @Default(0) int base,
    @Default(0) int profession,
    @JsonKey(name: 'completed_appointments') @Default(0) int completedAppointments,
    @JsonKey(name: 'no_show_penalty') @Default(0) int noShowPenalty,
    @JsonKey(name: 'report_penalty') @Default(0) int reportPenalty,
  }) = _TrustBreakdown;

  factory TrustBreakdown.fromJson(Map<String, dynamic> json) => _$TrustBreakdownFromJson(json);
}
