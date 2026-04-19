// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ThreadListingSummary _$ThreadListingSummaryFromJson(Map<String, dynamic> json) {
  return _ThreadListingSummary.fromJson(json);
}

/// @nodoc
mixin _$ThreadListingSummary {
  int get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;

  /// Serializes this ThreadListingSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThreadListingSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThreadListingSummaryCopyWith<ThreadListingSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadListingSummaryCopyWith<$Res> {
  factory $ThreadListingSummaryCopyWith(ThreadListingSummary value,
          $Res Function(ThreadListingSummary) then) =
      _$ThreadListingSummaryCopyWithImpl<$Res, ThreadListingSummary>;
  @useResult
  $Res call(
      {int id, String? title, @JsonKey(name: 'photo_url') String? photoUrl});
}

/// @nodoc
class _$ThreadListingSummaryCopyWithImpl<$Res,
        $Val extends ThreadListingSummary>
    implements $ThreadListingSummaryCopyWith<$Res> {
  _$ThreadListingSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThreadListingSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? photoUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThreadListingSummaryImplCopyWith<$Res>
    implements $ThreadListingSummaryCopyWith<$Res> {
  factory _$$ThreadListingSummaryImplCopyWith(_$ThreadListingSummaryImpl value,
          $Res Function(_$ThreadListingSummaryImpl) then) =
      __$$ThreadListingSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, String? title, @JsonKey(name: 'photo_url') String? photoUrl});
}

/// @nodoc
class __$$ThreadListingSummaryImplCopyWithImpl<$Res>
    extends _$ThreadListingSummaryCopyWithImpl<$Res, _$ThreadListingSummaryImpl>
    implements _$$ThreadListingSummaryImplCopyWith<$Res> {
  __$$ThreadListingSummaryImplCopyWithImpl(_$ThreadListingSummaryImpl _value,
      $Res Function(_$ThreadListingSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ThreadListingSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? photoUrl = freezed,
  }) {
    return _then(_$ThreadListingSummaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadListingSummaryImpl implements _ThreadListingSummary {
  const _$ThreadListingSummaryImpl(
      {required this.id,
      this.title,
      @JsonKey(name: 'photo_url') this.photoUrl});

  factory _$ThreadListingSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadListingSummaryImplFromJson(json);

  @override
  final int id;
  @override
  final String? title;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  @override
  String toString() {
    return 'ThreadListingSummary(id: $id, title: $title, photoUrl: $photoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadListingSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, photoUrl);

  /// Create a copy of ThreadListingSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadListingSummaryImplCopyWith<_$ThreadListingSummaryImpl>
      get copyWith =>
          __$$ThreadListingSummaryImplCopyWithImpl<_$ThreadListingSummaryImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadListingSummaryImplToJson(
      this,
    );
  }
}

abstract class _ThreadListingSummary implements ThreadListingSummary {
  const factory _ThreadListingSummary(
          {required final int id,
          final String? title,
          @JsonKey(name: 'photo_url') final String? photoUrl}) =
      _$ThreadListingSummaryImpl;

  factory _ThreadListingSummary.fromJson(Map<String, dynamic> json) =
      _$ThreadListingSummaryImpl.fromJson;

  @override
  int get id;
  @override
  String? get title;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;

  /// Create a copy of ThreadListingSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThreadListingSummaryImplCopyWith<_$ThreadListingSummaryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ThreadOtherUser _$ThreadOtherUserFromJson(Map<String, dynamic> json) {
  return _ThreadOtherUser.fromJson(json);
}

/// @nodoc
mixin _$ThreadOtherUser {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'trust_score')
  int get trustScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'response_time_bucket')
  String? get responseTimeBucket => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_active_bucket')
  String get lastActiveBucket => throw _privateConstructorUsedError;

  /// Serializes this ThreadOtherUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThreadOtherUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThreadOtherUserCopyWith<ThreadOtherUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadOtherUserCopyWith<$Res> {
  factory $ThreadOtherUserCopyWith(
          ThreadOtherUser value, $Res Function(ThreadOtherUser) then) =
      _$ThreadOtherUserCopyWithImpl<$Res, ThreadOtherUser>;
  @useResult
  $Res call(
      {int id,
      String name,
      @JsonKey(name: 'trust_score') int trustScore,
      @JsonKey(name: 'response_time_bucket') String? responseTimeBucket,
      @JsonKey(name: 'last_active_bucket') String lastActiveBucket});
}

/// @nodoc
class _$ThreadOtherUserCopyWithImpl<$Res, $Val extends ThreadOtherUser>
    implements $ThreadOtherUserCopyWith<$Res> {
  _$ThreadOtherUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThreadOtherUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trustScore = null,
    Object? responseTimeBucket = freezed,
    Object? lastActiveBucket = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      responseTimeBucket: freezed == responseTimeBucket
          ? _value.responseTimeBucket
          : responseTimeBucket // ignore: cast_nullable_to_non_nullable
              as String?,
      lastActiveBucket: null == lastActiveBucket
          ? _value.lastActiveBucket
          : lastActiveBucket // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThreadOtherUserImplCopyWith<$Res>
    implements $ThreadOtherUserCopyWith<$Res> {
  factory _$$ThreadOtherUserImplCopyWith(_$ThreadOtherUserImpl value,
          $Res Function(_$ThreadOtherUserImpl) then) =
      __$$ThreadOtherUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      @JsonKey(name: 'trust_score') int trustScore,
      @JsonKey(name: 'response_time_bucket') String? responseTimeBucket,
      @JsonKey(name: 'last_active_bucket') String lastActiveBucket});
}

/// @nodoc
class __$$ThreadOtherUserImplCopyWithImpl<$Res>
    extends _$ThreadOtherUserCopyWithImpl<$Res, _$ThreadOtherUserImpl>
    implements _$$ThreadOtherUserImplCopyWith<$Res> {
  __$$ThreadOtherUserImplCopyWithImpl(
      _$ThreadOtherUserImpl _value, $Res Function(_$ThreadOtherUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of ThreadOtherUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trustScore = null,
    Object? responseTimeBucket = freezed,
    Object? lastActiveBucket = null,
  }) {
    return _then(_$ThreadOtherUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      responseTimeBucket: freezed == responseTimeBucket
          ? _value.responseTimeBucket
          : responseTimeBucket // ignore: cast_nullable_to_non_nullable
              as String?,
      lastActiveBucket: null == lastActiveBucket
          ? _value.lastActiveBucket
          : lastActiveBucket // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadOtherUserImpl implements _ThreadOtherUser {
  const _$ThreadOtherUserImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'trust_score') required this.trustScore,
      @JsonKey(name: 'response_time_bucket') this.responseTimeBucket,
      @JsonKey(name: 'last_active_bucket') required this.lastActiveBucket});

  factory _$ThreadOtherUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadOtherUserImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(name: 'trust_score')
  final int trustScore;
  @override
  @JsonKey(name: 'response_time_bucket')
  final String? responseTimeBucket;
  @override
  @JsonKey(name: 'last_active_bucket')
  final String lastActiveBucket;

  @override
  String toString() {
    return 'ThreadOtherUser(id: $id, name: $name, trustScore: $trustScore, responseTimeBucket: $responseTimeBucket, lastActiveBucket: $lastActiveBucket)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadOtherUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.trustScore, trustScore) ||
                other.trustScore == trustScore) &&
            (identical(other.responseTimeBucket, responseTimeBucket) ||
                other.responseTimeBucket == responseTimeBucket) &&
            (identical(other.lastActiveBucket, lastActiveBucket) ||
                other.lastActiveBucket == lastActiveBucket));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, trustScore, responseTimeBucket, lastActiveBucket);

  /// Create a copy of ThreadOtherUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadOtherUserImplCopyWith<_$ThreadOtherUserImpl> get copyWith =>
      __$$ThreadOtherUserImplCopyWithImpl<_$ThreadOtherUserImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadOtherUserImplToJson(
      this,
    );
  }
}

abstract class _ThreadOtherUser implements ThreadOtherUser {
  const factory _ThreadOtherUser(
      {required final int id,
      required final String name,
      @JsonKey(name: 'trust_score') required final int trustScore,
      @JsonKey(name: 'response_time_bucket') final String? responseTimeBucket,
      @JsonKey(name: 'last_active_bucket')
      required final String lastActiveBucket}) = _$ThreadOtherUserImpl;

  factory _ThreadOtherUser.fromJson(Map<String, dynamic> json) =
      _$ThreadOtherUserImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'trust_score')
  int get trustScore;
  @override
  @JsonKey(name: 'response_time_bucket')
  String? get responseTimeBucket;
  @override
  @JsonKey(name: 'last_active_bucket')
  String get lastActiveBucket;

  /// Create a copy of ThreadOtherUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThreadOtherUserImplCopyWith<_$ThreadOtherUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ThreadMessage _$ThreadMessageFromJson(Map<String, dynamic> json) {
  return _ThreadMessage.fromJson(json);
}

/// @nodoc
mixin _$ThreadMessage {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sender_id')
  int get senderId => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'read_at')
  DateTime? get readAt => throw _privateConstructorUsedError;

  /// Serializes this ThreadMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThreadMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThreadMessageCopyWith<ThreadMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadMessageCopyWith<$Res> {
  factory $ThreadMessageCopyWith(
          ThreadMessage value, $Res Function(ThreadMessage) then) =
      _$ThreadMessageCopyWithImpl<$Res, ThreadMessage>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'sender_id') int senderId,
      String body,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'read_at') DateTime? readAt});
}

/// @nodoc
class _$ThreadMessageCopyWithImpl<$Res, $Val extends ThreadMessage>
    implements $ThreadMessageCopyWith<$Res> {
  _$ThreadMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThreadMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? body = null,
    Object? createdAt = freezed,
    Object? readAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as int,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThreadMessageImplCopyWith<$Res>
    implements $ThreadMessageCopyWith<$Res> {
  factory _$$ThreadMessageImplCopyWith(
          _$ThreadMessageImpl value, $Res Function(_$ThreadMessageImpl) then) =
      __$$ThreadMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'sender_id') int senderId,
      String body,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'read_at') DateTime? readAt});
}

/// @nodoc
class __$$ThreadMessageImplCopyWithImpl<$Res>
    extends _$ThreadMessageCopyWithImpl<$Res, _$ThreadMessageImpl>
    implements _$$ThreadMessageImplCopyWith<$Res> {
  __$$ThreadMessageImplCopyWithImpl(
      _$ThreadMessageImpl _value, $Res Function(_$ThreadMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ThreadMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? body = null,
    Object? createdAt = freezed,
    Object? readAt = freezed,
  }) {
    return _then(_$ThreadMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as int,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadMessageImpl implements _ThreadMessage {
  const _$ThreadMessageImpl(
      {required this.id,
      @JsonKey(name: 'sender_id') required this.senderId,
      required this.body,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'read_at') this.readAt});

  factory _$ThreadMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadMessageImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'sender_id')
  final int senderId;
  @override
  final String body;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  @override
  String toString() {
    return 'ThreadMessage(id: $id, senderId: $senderId, body: $body, createdAt: $createdAt, readAt: $readAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, senderId, body, createdAt, readAt);

  /// Create a copy of ThreadMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadMessageImplCopyWith<_$ThreadMessageImpl> get copyWith =>
      __$$ThreadMessageImplCopyWithImpl<_$ThreadMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadMessageImplToJson(
      this,
    );
  }
}

abstract class _ThreadMessage implements ThreadMessage {
  const factory _ThreadMessage(
      {required final int id,
      @JsonKey(name: 'sender_id') required final int senderId,
      required final String body,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'read_at') final DateTime? readAt}) = _$ThreadMessageImpl;

  factory _ThreadMessage.fromJson(Map<String, dynamic> json) =
      _$ThreadMessageImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'sender_id')
  int get senderId;
  @override
  String get body;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'read_at')
  DateTime? get readAt;

  /// Create a copy of ThreadMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThreadMessageImplCopyWith<_$ThreadMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Thread _$ThreadFromJson(Map<String, dynamic> json) {
  return _Thread.fromJson(json);
}

/// @nodoc
mixin _$Thread {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'listing_id')
  int get listingId => throw _privateConstructorUsedError;
  @JsonKey(name: 'buyer_id')
  int get buyerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seller_id')
  int get sellerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_message_at')
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_message_body')
  String? get lastMessageBody => throw _privateConstructorUsedError;
  @JsonKey(name: 'unread_count')
  int? get unreadCount => throw _privateConstructorUsedError;
  ThreadListingSummary? get listing => throw _privateConstructorUsedError;
  @JsonKey(name: 'other_user')
  ThreadOtherUser? get otherUser => throw _privateConstructorUsedError;
  List<ThreadMessage> get messages => throw _privateConstructorUsedError;

  /// Serializes this Thread to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThreadCopyWith<Thread> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadCopyWith<$Res> {
  factory $ThreadCopyWith(Thread value, $Res Function(Thread) then) =
      _$ThreadCopyWithImpl<$Res, Thread>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'listing_id') int listingId,
      @JsonKey(name: 'buyer_id') int buyerId,
      @JsonKey(name: 'seller_id') int sellerId,
      @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
      @JsonKey(name: 'last_message_body') String? lastMessageBody,
      @JsonKey(name: 'unread_count') int? unreadCount,
      ThreadListingSummary? listing,
      @JsonKey(name: 'other_user') ThreadOtherUser? otherUser,
      List<ThreadMessage> messages});

  $ThreadListingSummaryCopyWith<$Res>? get listing;
  $ThreadOtherUserCopyWith<$Res>? get otherUser;
}

/// @nodoc
class _$ThreadCopyWithImpl<$Res, $Val extends Thread>
    implements $ThreadCopyWith<$Res> {
  _$ThreadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listingId = null,
    Object? buyerId = null,
    Object? sellerId = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageBody = freezed,
    Object? unreadCount = freezed,
    Object? listing = freezed,
    Object? otherUser = freezed,
    Object? messages = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as int,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as int,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageBody: freezed == lastMessageBody
          ? _value.lastMessageBody
          : lastMessageBody // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: freezed == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int?,
      listing: freezed == listing
          ? _value.listing
          : listing // ignore: cast_nullable_to_non_nullable
              as ThreadListingSummary?,
      otherUser: freezed == otherUser
          ? _value.otherUser
          : otherUser // ignore: cast_nullable_to_non_nullable
              as ThreadOtherUser?,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ThreadMessage>,
    ) as $Val);
  }

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThreadListingSummaryCopyWith<$Res>? get listing {
    if (_value.listing == null) {
      return null;
    }

    return $ThreadListingSummaryCopyWith<$Res>(_value.listing!, (value) {
      return _then(_value.copyWith(listing: value) as $Val);
    });
  }

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThreadOtherUserCopyWith<$Res>? get otherUser {
    if (_value.otherUser == null) {
      return null;
    }

    return $ThreadOtherUserCopyWith<$Res>(_value.otherUser!, (value) {
      return _then(_value.copyWith(otherUser: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ThreadImplCopyWith<$Res> implements $ThreadCopyWith<$Res> {
  factory _$$ThreadImplCopyWith(
          _$ThreadImpl value, $Res Function(_$ThreadImpl) then) =
      __$$ThreadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'listing_id') int listingId,
      @JsonKey(name: 'buyer_id') int buyerId,
      @JsonKey(name: 'seller_id') int sellerId,
      @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
      @JsonKey(name: 'last_message_body') String? lastMessageBody,
      @JsonKey(name: 'unread_count') int? unreadCount,
      ThreadListingSummary? listing,
      @JsonKey(name: 'other_user') ThreadOtherUser? otherUser,
      List<ThreadMessage> messages});

  @override
  $ThreadListingSummaryCopyWith<$Res>? get listing;
  @override
  $ThreadOtherUserCopyWith<$Res>? get otherUser;
}

/// @nodoc
class __$$ThreadImplCopyWithImpl<$Res>
    extends _$ThreadCopyWithImpl<$Res, _$ThreadImpl>
    implements _$$ThreadImplCopyWith<$Res> {
  __$$ThreadImplCopyWithImpl(
      _$ThreadImpl _value, $Res Function(_$ThreadImpl) _then)
      : super(_value, _then);

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listingId = null,
    Object? buyerId = null,
    Object? sellerId = null,
    Object? lastMessageAt = freezed,
    Object? lastMessageBody = freezed,
    Object? unreadCount = freezed,
    Object? listing = freezed,
    Object? otherUser = freezed,
    Object? messages = null,
  }) {
    return _then(_$ThreadImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      listingId: null == listingId
          ? _value.listingId
          : listingId // ignore: cast_nullable_to_non_nullable
              as int,
      buyerId: null == buyerId
          ? _value.buyerId
          : buyerId // ignore: cast_nullable_to_non_nullable
              as int,
      sellerId: null == sellerId
          ? _value.sellerId
          : sellerId // ignore: cast_nullable_to_non_nullable
              as int,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageBody: freezed == lastMessageBody
          ? _value.lastMessageBody
          : lastMessageBody // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: freezed == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int?,
      listing: freezed == listing
          ? _value.listing
          : listing // ignore: cast_nullable_to_non_nullable
              as ThreadListingSummary?,
      otherUser: freezed == otherUser
          ? _value.otherUser
          : otherUser // ignore: cast_nullable_to_non_nullable
              as ThreadOtherUser?,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ThreadMessage>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadImpl implements _Thread {
  const _$ThreadImpl(
      {required this.id,
      @JsonKey(name: 'listing_id') required this.listingId,
      @JsonKey(name: 'buyer_id') required this.buyerId,
      @JsonKey(name: 'seller_id') required this.sellerId,
      @JsonKey(name: 'last_message_at') this.lastMessageAt,
      @JsonKey(name: 'last_message_body') this.lastMessageBody,
      @JsonKey(name: 'unread_count') this.unreadCount,
      this.listing,
      @JsonKey(name: 'other_user') this.otherUser,
      final List<ThreadMessage> messages = const <ThreadMessage>[]})
      : _messages = messages;

  factory _$ThreadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'listing_id')
  final int listingId;
  @override
  @JsonKey(name: 'buyer_id')
  final int buyerId;
  @override
  @JsonKey(name: 'seller_id')
  final int sellerId;
  @override
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @override
  @JsonKey(name: 'last_message_body')
  final String? lastMessageBody;
  @override
  @JsonKey(name: 'unread_count')
  final int? unreadCount;
  @override
  final ThreadListingSummary? listing;
  @override
  @JsonKey(name: 'other_user')
  final ThreadOtherUser? otherUser;
  final List<ThreadMessage> _messages;
  @override
  @JsonKey()
  List<ThreadMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'Thread(id: $id, listingId: $listingId, buyerId: $buyerId, sellerId: $sellerId, lastMessageAt: $lastMessageAt, lastMessageBody: $lastMessageBody, unreadCount: $unreadCount, listing: $listing, otherUser: $otherUser, messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.listingId, listingId) ||
                other.listingId == listingId) &&
            (identical(other.buyerId, buyerId) || other.buyerId == buyerId) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.lastMessageBody, lastMessageBody) ||
                other.lastMessageBody == lastMessageBody) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount) &&
            (identical(other.listing, listing) || other.listing == listing) &&
            (identical(other.otherUser, otherUser) ||
                other.otherUser == otherUser) &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      listingId,
      buyerId,
      sellerId,
      lastMessageAt,
      lastMessageBody,
      unreadCount,
      listing,
      otherUser,
      const DeepCollectionEquality().hash(_messages));

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadImplCopyWith<_$ThreadImpl> get copyWith =>
      __$$ThreadImplCopyWithImpl<_$ThreadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadImplToJson(
      this,
    );
  }
}

abstract class _Thread implements Thread {
  const factory _Thread(
      {required final int id,
      @JsonKey(name: 'listing_id') required final int listingId,
      @JsonKey(name: 'buyer_id') required final int buyerId,
      @JsonKey(name: 'seller_id') required final int sellerId,
      @JsonKey(name: 'last_message_at') final DateTime? lastMessageAt,
      @JsonKey(name: 'last_message_body') final String? lastMessageBody,
      @JsonKey(name: 'unread_count') final int? unreadCount,
      final ThreadListingSummary? listing,
      @JsonKey(name: 'other_user') final ThreadOtherUser? otherUser,
      final List<ThreadMessage> messages}) = _$ThreadImpl;

  factory _Thread.fromJson(Map<String, dynamic> json) = _$ThreadImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'listing_id')
  int get listingId;
  @override
  @JsonKey(name: 'buyer_id')
  int get buyerId;
  @override
  @JsonKey(name: 'seller_id')
  int get sellerId;
  @override
  @JsonKey(name: 'last_message_at')
  DateTime? get lastMessageAt;
  @override
  @JsonKey(name: 'last_message_body')
  String? get lastMessageBody;
  @override
  @JsonKey(name: 'unread_count')
  int? get unreadCount;
  @override
  ThreadListingSummary? get listing;
  @override
  @JsonKey(name: 'other_user')
  ThreadOtherUser? get otherUser;
  @override
  List<ThreadMessage> get messages;

  /// Create a copy of Thread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThreadImplCopyWith<_$ThreadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
