// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthPayloadImpl _$$AuthPayloadImplFromJson(Map<String, dynamic> json) =>
    _$AuthPayloadImpl(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthPayloadImplToJson(_$AuthPayloadImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

_$RefreshPayloadImpl _$$RefreshPayloadImplFromJson(Map<String, dynamic> json) =>
    _$RefreshPayloadImpl(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$$RefreshPayloadImplToJson(
        _$RefreshPayloadImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };
