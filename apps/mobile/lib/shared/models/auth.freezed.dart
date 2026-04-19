// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthPayload _$AuthPayloadFromJson(Map<String, dynamic> json) {
  return _AuthPayload.fromJson(json);
}

/// @nodoc
mixin _$AuthPayload {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String? get refreshToken => throw _privateConstructorUsedError;
  UserSummary get user => throw _privateConstructorUsedError;

  /// Serializes this AuthPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthPayloadCopyWith<AuthPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthPayloadCopyWith<$Res> {
  factory $AuthPayloadCopyWith(
          AuthPayload value, $Res Function(AuthPayload) then) =
      _$AuthPayloadCopyWithImpl<$Res, AuthPayload>;
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String? refreshToken,
      UserSummary user});

  $UserSummaryCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthPayloadCopyWithImpl<$Res, $Val extends AuthPayload>
    implements $AuthPayloadCopyWith<$Res> {
  _$AuthPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = freezed,
    Object? user = null,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserSummary,
    ) as $Val);
  }

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSummaryCopyWith<$Res> get user {
    return $UserSummaryCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthPayloadImplCopyWith<$Res>
    implements $AuthPayloadCopyWith<$Res> {
  factory _$$AuthPayloadImplCopyWith(
          _$AuthPayloadImpl value, $Res Function(_$AuthPayloadImpl) then) =
      __$$AuthPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String? refreshToken,
      UserSummary user});

  @override
  $UserSummaryCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthPayloadImplCopyWithImpl<$Res>
    extends _$AuthPayloadCopyWithImpl<$Res, _$AuthPayloadImpl>
    implements _$$AuthPayloadImplCopyWith<$Res> {
  __$$AuthPayloadImplCopyWithImpl(
      _$AuthPayloadImpl _value, $Res Function(_$AuthPayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = freezed,
    Object? user = null,
  }) {
    return _then(_$AuthPayloadImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserSummary,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthPayloadImpl implements _AuthPayload {
  const _$AuthPayloadImpl(
      {@JsonKey(name: 'access_token') required this.accessToken,
      @JsonKey(name: 'refresh_token') this.refreshToken,
      required this.user});

  factory _$AuthPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthPayloadImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @override
  final UserSummary user;

  @override
  String toString() {
    return 'AuthPayload(accessToken: $accessToken, refreshToken: $refreshToken, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthPayloadImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken, user);

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthPayloadImplCopyWith<_$AuthPayloadImpl> get copyWith =>
      __$$AuthPayloadImplCopyWithImpl<_$AuthPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthPayloadImplToJson(
      this,
    );
  }
}

abstract class _AuthPayload implements AuthPayload {
  const factory _AuthPayload(
      {@JsonKey(name: 'access_token') required final String accessToken,
      @JsonKey(name: 'refresh_token') final String? refreshToken,
      required final UserSummary user}) = _$AuthPayloadImpl;

  factory _AuthPayload.fromJson(Map<String, dynamic> json) =
      _$AuthPayloadImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  String? get refreshToken;
  @override
  UserSummary get user;

  /// Create a copy of AuthPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthPayloadImplCopyWith<_$AuthPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RefreshPayload _$RefreshPayloadFromJson(Map<String, dynamic> json) {
  return _RefreshPayload.fromJson(json);
}

/// @nodoc
mixin _$RefreshPayload {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String? get refreshToken => throw _privateConstructorUsedError;

  /// Serializes this RefreshPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RefreshPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefreshPayloadCopyWith<RefreshPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefreshPayloadCopyWith<$Res> {
  factory $RefreshPayloadCopyWith(
          RefreshPayload value, $Res Function(RefreshPayload) then) =
      _$RefreshPayloadCopyWithImpl<$Res, RefreshPayload>;
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String? refreshToken});
}

/// @nodoc
class _$RefreshPayloadCopyWithImpl<$Res, $Val extends RefreshPayload>
    implements $RefreshPayloadCopyWith<$Res> {
  _$RefreshPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefreshPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = freezed,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RefreshPayloadImplCopyWith<$Res>
    implements $RefreshPayloadCopyWith<$Res> {
  factory _$$RefreshPayloadImplCopyWith(_$RefreshPayloadImpl value,
          $Res Function(_$RefreshPayloadImpl) then) =
      __$$RefreshPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String? refreshToken});
}

/// @nodoc
class __$$RefreshPayloadImplCopyWithImpl<$Res>
    extends _$RefreshPayloadCopyWithImpl<$Res, _$RefreshPayloadImpl>
    implements _$$RefreshPayloadImplCopyWith<$Res> {
  __$$RefreshPayloadImplCopyWithImpl(
      _$RefreshPayloadImpl _value, $Res Function(_$RefreshPayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of RefreshPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = freezed,
  }) {
    return _then(_$RefreshPayloadImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RefreshPayloadImpl implements _RefreshPayload {
  const _$RefreshPayloadImpl(
      {@JsonKey(name: 'access_token') required this.accessToken,
      @JsonKey(name: 'refresh_token') this.refreshToken});

  factory _$RefreshPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$RefreshPayloadImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @override
  String toString() {
    return 'RefreshPayload(accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshPayloadImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken);

  /// Create a copy of RefreshPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshPayloadImplCopyWith<_$RefreshPayloadImpl> get copyWith =>
      __$$RefreshPayloadImplCopyWithImpl<_$RefreshPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RefreshPayloadImplToJson(
      this,
    );
  }
}

abstract class _RefreshPayload implements RefreshPayload {
  const factory _RefreshPayload(
          {@JsonKey(name: 'access_token') required final String accessToken,
          @JsonKey(name: 'refresh_token') final String? refreshToken}) =
      _$RefreshPayloadImpl;

  factory _RefreshPayload.fromJson(Map<String, dynamic> json) =
      _$RefreshPayloadImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  String? get refreshToken;

  /// Create a copy of RefreshPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefreshPayloadImplCopyWith<_$RefreshPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
