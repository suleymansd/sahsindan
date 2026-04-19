// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiErrorResponseImpl _$$ApiErrorResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$ApiErrorResponseImpl(
      code: json['code'] as String,
      message: json['message'] as String,
      details:
          json['details'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$$ApiErrorResponseImplToJson(
        _$ApiErrorResponseImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };

_$ApiEnvelopeImpl<T> _$$ApiEnvelopeImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    _$ApiEnvelopeImpl<T>(
      data: fromJsonT(json['data']),
      meta: json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$$ApiEnvelopeImplToJson<T>(
  _$ApiEnvelopeImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': toJsonT(instance.data),
      'meta': instance.meta,
    };

_$ApiErrorEnvelopeImpl _$$ApiErrorEnvelopeImplFromJson(
        Map<String, dynamic> json) =>
    _$ApiErrorEnvelopeImpl(
      error: ApiErrorResponse.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ApiErrorEnvelopeImplToJson(
        _$ApiErrorEnvelopeImpl instance) =>
    <String, dynamic>{
      'error': instance.error,
    };
