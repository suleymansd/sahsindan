// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VerificationStatusImpl _$$VerificationStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$VerificationStatusImpl(
      status: json['status'] as String,
      reason: json['reason'] as String?,
      reasonCode: json['reason_code'] as String?,
    );

Map<String, dynamic> _$$VerificationStatusImplToJson(
        _$VerificationStatusImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'reason': instance.reason,
      'reason_code': instance.reasonCode,
    };
