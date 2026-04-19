// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CarDetail _$CarDetailFromJson(Map<String, dynamic> json) {
  return _CarDetail.fromJson(json);
}

/// @nodoc
mixin _$CarDetail {
  String get brand => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  int get mileage => throw _privateConstructorUsedError;
  String get transmission => throw _privateConstructorUsedError;
  String get fuel => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  @JsonKey(name: 'vin_optional')
  String? get vinOptional => throw _privateConstructorUsedError;

  /// Serializes this CarDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CarDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CarDetailCopyWith<CarDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CarDetailCopyWith<$Res> {
  factory $CarDetailCopyWith(CarDetail value, $Res Function(CarDetail) then) =
      _$CarDetailCopyWithImpl<$Res, CarDetail>;
  @useResult
  $Res call(
      {String brand,
      String model,
      int year,
      int mileage,
      String transmission,
      String fuel,
      String color,
      @JsonKey(name: 'vin_optional') String? vinOptional});
}

/// @nodoc
class _$CarDetailCopyWithImpl<$Res, $Val extends CarDetail>
    implements $CarDetailCopyWith<$Res> {
  _$CarDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CarDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? model = null,
    Object? year = null,
    Object? mileage = null,
    Object? transmission = null,
    Object? fuel = null,
    Object? color = null,
    Object? vinOptional = freezed,
  }) {
    return _then(_value.copyWith(
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      mileage: null == mileage
          ? _value.mileage
          : mileage // ignore: cast_nullable_to_non_nullable
              as int,
      transmission: null == transmission
          ? _value.transmission
          : transmission // ignore: cast_nullable_to_non_nullable
              as String,
      fuel: null == fuel
          ? _value.fuel
          : fuel // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      vinOptional: freezed == vinOptional
          ? _value.vinOptional
          : vinOptional // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CarDetailImplCopyWith<$Res>
    implements $CarDetailCopyWith<$Res> {
  factory _$$CarDetailImplCopyWith(
          _$CarDetailImpl value, $Res Function(_$CarDetailImpl) then) =
      __$$CarDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String brand,
      String model,
      int year,
      int mileage,
      String transmission,
      String fuel,
      String color,
      @JsonKey(name: 'vin_optional') String? vinOptional});
}

/// @nodoc
class __$$CarDetailImplCopyWithImpl<$Res>
    extends _$CarDetailCopyWithImpl<$Res, _$CarDetailImpl>
    implements _$$CarDetailImplCopyWith<$Res> {
  __$$CarDetailImplCopyWithImpl(
      _$CarDetailImpl _value, $Res Function(_$CarDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of CarDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? model = null,
    Object? year = null,
    Object? mileage = null,
    Object? transmission = null,
    Object? fuel = null,
    Object? color = null,
    Object? vinOptional = freezed,
  }) {
    return _then(_$CarDetailImpl(
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      mileage: null == mileage
          ? _value.mileage
          : mileage // ignore: cast_nullable_to_non_nullable
              as int,
      transmission: null == transmission
          ? _value.transmission
          : transmission // ignore: cast_nullable_to_non_nullable
              as String,
      fuel: null == fuel
          ? _value.fuel
          : fuel // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      vinOptional: freezed == vinOptional
          ? _value.vinOptional
          : vinOptional // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CarDetailImpl implements _CarDetail {
  const _$CarDetailImpl(
      {required this.brand,
      required this.model,
      required this.year,
      required this.mileage,
      required this.transmission,
      required this.fuel,
      required this.color,
      @JsonKey(name: 'vin_optional') this.vinOptional});

  factory _$CarDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$CarDetailImplFromJson(json);

  @override
  final String brand;
  @override
  final String model;
  @override
  final int year;
  @override
  final int mileage;
  @override
  final String transmission;
  @override
  final String fuel;
  @override
  final String color;
  @override
  @JsonKey(name: 'vin_optional')
  final String? vinOptional;

  @override
  String toString() {
    return 'CarDetail(brand: $brand, model: $model, year: $year, mileage: $mileage, transmission: $transmission, fuel: $fuel, color: $color, vinOptional: $vinOptional)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CarDetailImpl &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.mileage, mileage) || other.mileage == mileage) &&
            (identical(other.transmission, transmission) ||
                other.transmission == transmission) &&
            (identical(other.fuel, fuel) || other.fuel == fuel) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.vinOptional, vinOptional) ||
                other.vinOptional == vinOptional));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, brand, model, year, mileage,
      transmission, fuel, color, vinOptional);

  /// Create a copy of CarDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CarDetailImplCopyWith<_$CarDetailImpl> get copyWith =>
      __$$CarDetailImplCopyWithImpl<_$CarDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CarDetailImplToJson(
      this,
    );
  }
}

abstract class _CarDetail implements CarDetail {
  const factory _CarDetail(
          {required final String brand,
          required final String model,
          required final int year,
          required final int mileage,
          required final String transmission,
          required final String fuel,
          required final String color,
          @JsonKey(name: 'vin_optional') final String? vinOptional}) =
      _$CarDetailImpl;

  factory _CarDetail.fromJson(Map<String, dynamic> json) =
      _$CarDetailImpl.fromJson;

  @override
  String get brand;
  @override
  String get model;
  @override
  int get year;
  @override
  int get mileage;
  @override
  String get transmission;
  @override
  String get fuel;
  @override
  String get color;
  @override
  @JsonKey(name: 'vin_optional')
  String? get vinOptional;

  /// Create a copy of CarDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CarDetailImplCopyWith<_$CarDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ListingPhoto _$ListingPhotoFromJson(Map<String, dynamic> json) {
  return _ListingPhoto.fromJson(json);
}

/// @nodoc
mixin _$ListingPhoto {
  int get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ListingPhoto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ListingPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListingPhotoCopyWith<ListingPhoto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListingPhotoCopyWith<$Res> {
  factory $ListingPhotoCopyWith(
          ListingPhoto value, $Res Function(ListingPhoto) then) =
      _$ListingPhotoCopyWithImpl<$Res, ListingPhoto>;
  @useResult
  $Res call({int id, String url, @JsonKey(name: 'sort_order') int sortOrder});
}

/// @nodoc
class _$ListingPhotoCopyWithImpl<$Res, $Val extends ListingPhoto>
    implements $ListingPhotoCopyWith<$Res> {
  _$ListingPhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ListingPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ListingPhotoImplCopyWith<$Res>
    implements $ListingPhotoCopyWith<$Res> {
  factory _$$ListingPhotoImplCopyWith(
          _$ListingPhotoImpl value, $Res Function(_$ListingPhotoImpl) then) =
      __$$ListingPhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String url, @JsonKey(name: 'sort_order') int sortOrder});
}

/// @nodoc
class __$$ListingPhotoImplCopyWithImpl<$Res>
    extends _$ListingPhotoCopyWithImpl<$Res, _$ListingPhotoImpl>
    implements _$$ListingPhotoImplCopyWith<$Res> {
  __$$ListingPhotoImplCopyWithImpl(
      _$ListingPhotoImpl _value, $Res Function(_$ListingPhotoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ListingPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ListingPhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ListingPhotoImpl implements _ListingPhoto {
  const _$ListingPhotoImpl(
      {required this.id,
      required this.url,
      @JsonKey(name: 'sort_order') required this.sortOrder});

  factory _$ListingPhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListingPhotoImplFromJson(json);

  @override
  final int id;
  @override
  final String url;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @override
  String toString() {
    return 'ListingPhoto(id: $id, url: $url, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListingPhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, sortOrder);

  /// Create a copy of ListingPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListingPhotoImplCopyWith<_$ListingPhotoImpl> get copyWith =>
      __$$ListingPhotoImplCopyWithImpl<_$ListingPhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListingPhotoImplToJson(
      this,
    );
  }
}

abstract class _ListingPhoto implements ListingPhoto {
  const factory _ListingPhoto(
          {required final int id,
          required final String url,
          @JsonKey(name: 'sort_order') required final int sortOrder}) =
      _$ListingPhotoImpl;

  factory _ListingPhoto.fromJson(Map<String, dynamic> json) =
      _$ListingPhotoImpl.fromJson;

  @override
  int get id;
  @override
  String get url;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;

  /// Create a copy of ListingPhoto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListingPhotoImplCopyWith<_$ListingPhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ListingOwner _$ListingOwnerFromJson(Map<String, dynamic> json) {
  return _ListingOwner.fromJson(json);
}

/// @nodoc
mixin _$ListingOwner {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'trust_score')
  int get trustScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'response_time_bucket')
  String? get responseTimeBucket => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_active_bucket')
  String get lastActiveBucket => throw _privateConstructorUsedError;

  /// Serializes this ListingOwner to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ListingOwner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListingOwnerCopyWith<ListingOwner> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListingOwnerCopyWith<$Res> {
  factory $ListingOwnerCopyWith(
          ListingOwner value, $Res Function(ListingOwner) then) =
      _$ListingOwnerCopyWithImpl<$Res, ListingOwner>;
  @useResult
  $Res call(
      {int id,
      String name,
      @JsonKey(name: 'trust_score') int trustScore,
      @JsonKey(name: 'response_time_bucket') String? responseTimeBucket,
      @JsonKey(name: 'last_active_bucket') String lastActiveBucket});
}

/// @nodoc
class _$ListingOwnerCopyWithImpl<$Res, $Val extends ListingOwner>
    implements $ListingOwnerCopyWith<$Res> {
  _$ListingOwnerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ListingOwner
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
abstract class _$$ListingOwnerImplCopyWith<$Res>
    implements $ListingOwnerCopyWith<$Res> {
  factory _$$ListingOwnerImplCopyWith(
          _$ListingOwnerImpl value, $Res Function(_$ListingOwnerImpl) then) =
      __$$ListingOwnerImplCopyWithImpl<$Res>;
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
class __$$ListingOwnerImplCopyWithImpl<$Res>
    extends _$ListingOwnerCopyWithImpl<$Res, _$ListingOwnerImpl>
    implements _$$ListingOwnerImplCopyWith<$Res> {
  __$$ListingOwnerImplCopyWithImpl(
      _$ListingOwnerImpl _value, $Res Function(_$ListingOwnerImpl) _then)
      : super(_value, _then);

  /// Create a copy of ListingOwner
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
    return _then(_$ListingOwnerImpl(
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
class _$ListingOwnerImpl implements _ListingOwner {
  const _$ListingOwnerImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'trust_score') required this.trustScore,
      @JsonKey(name: 'response_time_bucket') this.responseTimeBucket,
      @JsonKey(name: 'last_active_bucket') required this.lastActiveBucket});

  factory _$ListingOwnerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListingOwnerImplFromJson(json);

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
    return 'ListingOwner(id: $id, name: $name, trustScore: $trustScore, responseTimeBucket: $responseTimeBucket, lastActiveBucket: $lastActiveBucket)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListingOwnerImpl &&
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

  /// Create a copy of ListingOwner
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListingOwnerImplCopyWith<_$ListingOwnerImpl> get copyWith =>
      __$$ListingOwnerImplCopyWithImpl<_$ListingOwnerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListingOwnerImplToJson(
      this,
    );
  }
}

abstract class _ListingOwner implements ListingOwner {
  const factory _ListingOwner(
      {required final int id,
      required final String name,
      @JsonKey(name: 'trust_score') required final int trustScore,
      @JsonKey(name: 'response_time_bucket') final String? responseTimeBucket,
      @JsonKey(name: 'last_active_bucket')
      required final String lastActiveBucket}) = _$ListingOwnerImpl;

  factory _ListingOwner.fromJson(Map<String, dynamic> json) =
      _$ListingOwnerImpl.fromJson;

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

  /// Create a copy of ListingOwner
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListingOwnerImplCopyWith<_$ListingOwnerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Listing _$ListingFromJson(Map<String, dynamic> json) {
  return _Listing.fromJson(json);
}

/// @nodoc
mixin _$Listing {
  int get id => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'stale_state')
  String? get staleState => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_confirmed_at')
  DateTime get lastConfirmedAt => throw _privateConstructorUsedError;
  ListingOwner get owner => throw _privateConstructorUsedError;
  @JsonKey(name: 'car_details')
  CarDetail get carDetails => throw _privateConstructorUsedError;
  List<ListingPhoto> get photos => throw _privateConstructorUsedError;

  /// Serializes this Listing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListingCopyWith<Listing> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListingCopyWith<$Res> {
  factory $ListingCopyWith(Listing value, $Res Function(Listing) then) =
      _$ListingCopyWithImpl<$Res, Listing>;
  @useResult
  $Res call(
      {int id,
      String state,
      @JsonKey(name: 'stale_state') String? staleState,
      String title,
      String description,
      double price,
      String city,
      String district,
      @JsonKey(name: 'last_confirmed_at') DateTime lastConfirmedAt,
      ListingOwner owner,
      @JsonKey(name: 'car_details') CarDetail carDetails,
      List<ListingPhoto> photos});

  $ListingOwnerCopyWith<$Res> get owner;
  $CarDetailCopyWith<$Res> get carDetails;
}

/// @nodoc
class _$ListingCopyWithImpl<$Res, $Val extends Listing>
    implements $ListingCopyWith<$Res> {
  _$ListingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? state = null,
    Object? staleState = freezed,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? city = null,
    Object? district = null,
    Object? lastConfirmedAt = null,
    Object? owner = null,
    Object? carDetails = null,
    Object? photos = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      staleState: freezed == staleState
          ? _value.staleState
          : staleState // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      lastConfirmedAt: null == lastConfirmedAt
          ? _value.lastConfirmedAt
          : lastConfirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as ListingOwner,
      carDetails: null == carDetails
          ? _value.carDetails
          : carDetails // ignore: cast_nullable_to_non_nullable
              as CarDetail,
      photos: null == photos
          ? _value.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<ListingPhoto>,
    ) as $Val);
  }

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ListingOwnerCopyWith<$Res> get owner {
    return $ListingOwnerCopyWith<$Res>(_value.owner, (value) {
      return _then(_value.copyWith(owner: value) as $Val);
    });
  }

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CarDetailCopyWith<$Res> get carDetails {
    return $CarDetailCopyWith<$Res>(_value.carDetails, (value) {
      return _then(_value.copyWith(carDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ListingImplCopyWith<$Res> implements $ListingCopyWith<$Res> {
  factory _$$ListingImplCopyWith(
          _$ListingImpl value, $Res Function(_$ListingImpl) then) =
      __$$ListingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String state,
      @JsonKey(name: 'stale_state') String? staleState,
      String title,
      String description,
      double price,
      String city,
      String district,
      @JsonKey(name: 'last_confirmed_at') DateTime lastConfirmedAt,
      ListingOwner owner,
      @JsonKey(name: 'car_details') CarDetail carDetails,
      List<ListingPhoto> photos});

  @override
  $ListingOwnerCopyWith<$Res> get owner;
  @override
  $CarDetailCopyWith<$Res> get carDetails;
}

/// @nodoc
class __$$ListingImplCopyWithImpl<$Res>
    extends _$ListingCopyWithImpl<$Res, _$ListingImpl>
    implements _$$ListingImplCopyWith<$Res> {
  __$$ListingImplCopyWithImpl(
      _$ListingImpl _value, $Res Function(_$ListingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? state = null,
    Object? staleState = freezed,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? city = null,
    Object? district = null,
    Object? lastConfirmedAt = null,
    Object? owner = null,
    Object? carDetails = null,
    Object? photos = null,
  }) {
    return _then(_$ListingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      staleState: freezed == staleState
          ? _value.staleState
          : staleState // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      lastConfirmedAt: null == lastConfirmedAt
          ? _value.lastConfirmedAt
          : lastConfirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      owner: null == owner
          ? _value.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as ListingOwner,
      carDetails: null == carDetails
          ? _value.carDetails
          : carDetails // ignore: cast_nullable_to_non_nullable
              as CarDetail,
      photos: null == photos
          ? _value._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<ListingPhoto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ListingImpl implements _Listing {
  const _$ListingImpl(
      {required this.id,
      required this.state,
      @JsonKey(name: 'stale_state') this.staleState,
      required this.title,
      required this.description,
      required this.price,
      required this.city,
      required this.district,
      @JsonKey(name: 'last_confirmed_at') required this.lastConfirmedAt,
      required this.owner,
      @JsonKey(name: 'car_details') required this.carDetails,
      final List<ListingPhoto> photos = const <ListingPhoto>[]})
      : _photos = photos;

  factory _$ListingImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListingImplFromJson(json);

  @override
  final int id;
  @override
  final String state;
  @override
  @JsonKey(name: 'stale_state')
  final String? staleState;
  @override
  final String title;
  @override
  final String description;
  @override
  final double price;
  @override
  final String city;
  @override
  final String district;
  @override
  @JsonKey(name: 'last_confirmed_at')
  final DateTime lastConfirmedAt;
  @override
  final ListingOwner owner;
  @override
  @JsonKey(name: 'car_details')
  final CarDetail carDetails;
  final List<ListingPhoto> _photos;
  @override
  @JsonKey()
  List<ListingPhoto> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  @override
  String toString() {
    return 'Listing(id: $id, state: $state, staleState: $staleState, title: $title, description: $description, price: $price, city: $city, district: $district, lastConfirmedAt: $lastConfirmedAt, owner: $owner, carDetails: $carDetails, photos: $photos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.staleState, staleState) ||
                other.staleState == staleState) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.lastConfirmedAt, lastConfirmedAt) ||
                other.lastConfirmedAt == lastConfirmedAt) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.carDetails, carDetails) ||
                other.carDetails == carDetails) &&
            const DeepCollectionEquality().equals(other._photos, _photos));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      state,
      staleState,
      title,
      description,
      price,
      city,
      district,
      lastConfirmedAt,
      owner,
      carDetails,
      const DeepCollectionEquality().hash(_photos));

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListingImplCopyWith<_$ListingImpl> get copyWith =>
      __$$ListingImplCopyWithImpl<_$ListingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListingImplToJson(
      this,
    );
  }
}

abstract class _Listing implements Listing {
  const factory _Listing(
      {required final int id,
      required final String state,
      @JsonKey(name: 'stale_state') final String? staleState,
      required final String title,
      required final String description,
      required final double price,
      required final String city,
      required final String district,
      @JsonKey(name: 'last_confirmed_at')
      required final DateTime lastConfirmedAt,
      required final ListingOwner owner,
      @JsonKey(name: 'car_details') required final CarDetail carDetails,
      final List<ListingPhoto> photos}) = _$ListingImpl;

  factory _Listing.fromJson(Map<String, dynamic> json) = _$ListingImpl.fromJson;

  @override
  int get id;
  @override
  String get state;
  @override
  @JsonKey(name: 'stale_state')
  String? get staleState;
  @override
  String get title;
  @override
  String get description;
  @override
  double get price;
  @override
  String get city;
  @override
  String get district;
  @override
  @JsonKey(name: 'last_confirmed_at')
  DateTime get lastConfirmedAt;
  @override
  ListingOwner get owner;
  @override
  @JsonKey(name: 'car_details')
  CarDetail get carDetails;
  @override
  List<ListingPhoto> get photos;

  /// Create a copy of Listing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListingImplCopyWith<_$ListingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
