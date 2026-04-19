// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppErrorCopyWith<$Res> {
  factory $AppErrorCopyWith(AppError value, $Res Function(AppError) then) =
      _$AppErrorCopyWithImpl<$Res, AppError>;
}

/// @nodoc
class _$AppErrorCopyWithImpl<$Res, $Val extends AppError>
    implements $AppErrorCopyWith<$Res> {
  _$AppErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NetworkErrorImplCopyWith<$Res> {
  factory _$$NetworkErrorImplCopyWith(
          _$NetworkErrorImpl value, $Res Function(_$NetworkErrorImpl) then) =
      __$$NetworkErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NetworkErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$NetworkErrorImpl>
    implements _$$NetworkErrorImplCopyWith<$Res> {
  __$$NetworkErrorImplCopyWithImpl(
      _$NetworkErrorImpl _value, $Res Function(_$NetworkErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$NetworkErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$NetworkErrorImpl implements _NetworkError {
  const _$NetworkErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AppError.network(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkErrorImplCopyWith<_$NetworkErrorImpl> get copyWith =>
      __$$NetworkErrorImplCopyWithImpl<_$NetworkErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return network(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return network?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class _NetworkError implements AppError {
  const factory _NetworkError({required final String message}) =
      _$NetworkErrorImpl;

  String get message;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkErrorImplCopyWith<_$NetworkErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnauthorizedErrorImplCopyWith<$Res> {
  factory _$$UnauthorizedErrorImplCopyWith(_$UnauthorizedErrorImpl value,
          $Res Function(_$UnauthorizedErrorImpl) then) =
      __$$UnauthorizedErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$UnauthorizedErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$UnauthorizedErrorImpl>
    implements _$$UnauthorizedErrorImplCopyWith<$Res> {
  __$$UnauthorizedErrorImplCopyWithImpl(_$UnauthorizedErrorImpl _value,
      $Res Function(_$UnauthorizedErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$UnauthorizedErrorImpl implements _UnauthorizedError {
  const _$UnauthorizedErrorImpl();

  @override
  String toString() {
    return 'AppError.unauthorized()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$UnauthorizedErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return unauthorized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return unauthorized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return unauthorized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return unauthorized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(this);
    }
    return orElse();
  }
}

abstract class _UnauthorizedError implements AppError {
  const factory _UnauthorizedError() = _$UnauthorizedErrorImpl;
}

/// @nodoc
abstract class _$$ForbiddenErrorImplCopyWith<$Res> {
  factory _$$ForbiddenErrorImplCopyWith(_$ForbiddenErrorImpl value,
          $Res Function(_$ForbiddenErrorImpl) then) =
      __$$ForbiddenErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ForbiddenErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ForbiddenErrorImpl>
    implements _$$ForbiddenErrorImplCopyWith<$Res> {
  __$$ForbiddenErrorImplCopyWithImpl(
      _$ForbiddenErrorImpl _value, $Res Function(_$ForbiddenErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ForbiddenErrorImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ForbiddenErrorImpl implements _ForbiddenError {
  const _$ForbiddenErrorImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'AppError.forbidden(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForbiddenErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForbiddenErrorImplCopyWith<_$ForbiddenErrorImpl> get copyWith =>
      __$$ForbiddenErrorImplCopyWithImpl<_$ForbiddenErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return forbidden(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return forbidden?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return forbidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return forbidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden(this);
    }
    return orElse();
  }
}

abstract class _ForbiddenError implements AppError {
  const factory _ForbiddenError({final String? message}) = _$ForbiddenErrorImpl;

  String? get message;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForbiddenErrorImplCopyWith<_$ForbiddenErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RateLimitedErrorImplCopyWith<$Res> {
  factory _$$RateLimitedErrorImplCopyWith(_$RateLimitedErrorImpl value,
          $Res Function(_$RateLimitedErrorImpl) then) =
      __$$RateLimitedErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$RateLimitedErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$RateLimitedErrorImpl>
    implements _$$RateLimitedErrorImplCopyWith<$Res> {
  __$$RateLimitedErrorImplCopyWithImpl(_$RateLimitedErrorImpl _value,
      $Res Function(_$RateLimitedErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$RateLimitedErrorImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$RateLimitedErrorImpl implements _RateLimitedError {
  const _$RateLimitedErrorImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'AppError.rateLimited(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RateLimitedErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RateLimitedErrorImplCopyWith<_$RateLimitedErrorImpl> get copyWith =>
      __$$RateLimitedErrorImplCopyWithImpl<_$RateLimitedErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return rateLimited(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return rateLimited?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimited != null) {
      return rateLimited(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return rateLimited(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return rateLimited?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimited != null) {
      return rateLimited(this);
    }
    return orElse();
  }
}

abstract class _RateLimitedError implements AppError {
  const factory _RateLimitedError({final String? message}) =
      _$RateLimitedErrorImpl;

  String? get message;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RateLimitedErrorImplCopyWith<_$RateLimitedErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ValidationErrorImplCopyWith<$Res> {
  factory _$$ValidationErrorImplCopyWith(_$ValidationErrorImpl value,
          $Res Function(_$ValidationErrorImpl) then) =
      __$$ValidationErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message, Map<String, dynamic>? details});
}

/// @nodoc
class __$$ValidationErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ValidationErrorImpl>
    implements _$$ValidationErrorImplCopyWith<$Res> {
  __$$ValidationErrorImplCopyWithImpl(
      _$ValidationErrorImpl _value, $Res Function(_$ValidationErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
    Object? details = freezed,
  }) {
    return _then(_$ValidationErrorImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc

class _$ValidationErrorImpl implements _ValidationError {
  const _$ValidationErrorImpl(
      {this.message, final Map<String, dynamic>? details})
      : _details = details;

  @override
  final String? message;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AppError.validation(message: $message, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, message, const DeepCollectionEquality().hash(_details));

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      __$$ValidationErrorImplCopyWithImpl<_$ValidationErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return validation(message, details);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return validation?.call(message, details);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(message, details);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return validation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return validation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(this);
    }
    return orElse();
  }
}

abstract class _ValidationError implements AppError {
  const factory _ValidationError(
      {final String? message,
      final Map<String, dynamic>? details}) = _$ValidationErrorImpl;

  String? get message;
  Map<String, dynamic>? get details;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ServerErrorImplCopyWith<$Res> {
  factory _$$ServerErrorImplCopyWith(
          _$ServerErrorImpl value, $Res Function(_$ServerErrorImpl) then) =
      __$$ServerErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ServerErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ServerErrorImpl>
    implements _$$ServerErrorImplCopyWith<$Res> {
  __$$ServerErrorImplCopyWithImpl(
      _$ServerErrorImpl _value, $Res Function(_$ServerErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ServerErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ServerErrorImpl implements _ServerError {
  const _$ServerErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AppError.server(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerErrorImplCopyWith<_$ServerErrorImpl> get copyWith =>
      __$$ServerErrorImplCopyWithImpl<_$ServerErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return server(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return server?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return server(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return server?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(this);
    }
    return orElse();
  }
}

abstract class _ServerError implements AppError {
  const factory _ServerError({required final String message}) =
      _$ServerErrorImpl;

  String get message;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerErrorImplCopyWith<_$ServerErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownErrorImplCopyWith<$Res> {
  factory _$$UnknownErrorImplCopyWith(
          _$UnknownErrorImpl value, $Res Function(_$UnknownErrorImpl) then) =
      __$$UnknownErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnknownErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$UnknownErrorImpl>
    implements _$$UnknownErrorImplCopyWith<$Res> {
  __$$UnknownErrorImplCopyWithImpl(
      _$UnknownErrorImpl _value, $Res Function(_$UnknownErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$UnknownErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$UnknownErrorImpl implements _UnknownError {
  const _$UnknownErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'AppError.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownErrorImplCopyWith<_$UnknownErrorImpl> get copyWith =>
      __$$UnknownErrorImplCopyWithImpl<_$UnknownErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) network,
    required TResult Function() unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) rateLimited,
    required TResult Function(String? message, Map<String, dynamic>? details)
        validation,
    required TResult Function(String message) server,
    required TResult Function(String message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? network,
    TResult? Function()? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? rateLimited,
    TResult? Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult? Function(String message)? server,
    TResult? Function(String message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? network,
    TResult Function()? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? rateLimited,
    TResult Function(String? message, Map<String, dynamic>? details)?
        validation,
    TResult Function(String message)? server,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) network,
    required TResult Function(_UnauthorizedError value) unauthorized,
    required TResult Function(_ForbiddenError value) forbidden,
    required TResult Function(_RateLimitedError value) rateLimited,
    required TResult Function(_ValidationError value) validation,
    required TResult Function(_ServerError value) server,
    required TResult Function(_UnknownError value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? network,
    TResult? Function(_UnauthorizedError value)? unauthorized,
    TResult? Function(_ForbiddenError value)? forbidden,
    TResult? Function(_RateLimitedError value)? rateLimited,
    TResult? Function(_ValidationError value)? validation,
    TResult? Function(_ServerError value)? server,
    TResult? Function(_UnknownError value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? network,
    TResult Function(_UnauthorizedError value)? unauthorized,
    TResult Function(_ForbiddenError value)? forbidden,
    TResult Function(_RateLimitedError value)? rateLimited,
    TResult Function(_ValidationError value)? validation,
    TResult Function(_ServerError value)? server,
    TResult Function(_UnknownError value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class _UnknownError implements AppError {
  const factory _UnknownError({required final String message}) =
      _$UnknownErrorImpl;

  String get message;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownErrorImplCopyWith<_$UnknownErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
