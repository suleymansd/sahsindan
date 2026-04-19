// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trust_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrustBreakdownImpl _$$TrustBreakdownImplFromJson(Map<String, dynamic> json) =>
    _$TrustBreakdownImpl(
      total: (json['total'] as num?)?.toInt() ?? 0,
      base: (json['base'] as num?)?.toInt() ?? 0,
      profession: (json['profession'] as num?)?.toInt() ?? 0,
      completedAppointments:
          (json['completed_appointments'] as num?)?.toInt() ?? 0,
      noShowPenalty: (json['no_show_penalty'] as num?)?.toInt() ?? 0,
      reportPenalty: (json['report_penalty'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TrustBreakdownImplToJson(
        _$TrustBreakdownImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'base': instance.base,
      'profession': instance.profession,
      'completed_appointments': instance.completedAppointments,
      'no_show_penalty': instance.noShowPenalty,
      'report_penalty': instance.reportPenalty,
    };
