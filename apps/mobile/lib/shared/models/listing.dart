// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

@freezed
class CarDetail with _$CarDetail {
  const factory CarDetail({
    required String brand,
    required String model,
    required int year,
    required int mileage,
    required String transmission,
    required String fuel,
    required String color,
    @JsonKey(name: 'vin_optional') String? vinOptional,
  }) = _CarDetail;

  factory CarDetail.fromJson(Map<String, dynamic> json) => _$CarDetailFromJson(json);
}

@freezed
class ListingPhoto with _$ListingPhoto {
  const factory ListingPhoto({
    required int id,
    required String url,
    @JsonKey(name: 'sort_order') required int sortOrder,
  }) = _ListingPhoto;

  factory ListingPhoto.fromJson(Map<String, dynamic> json) => _$ListingPhotoFromJson(json);
}

@freezed
class ListingOwner with _$ListingOwner {
  const factory ListingOwner({
    required int id,
    required String name,
    @JsonKey(name: 'trust_score') required int trustScore,
    @JsonKey(name: 'response_time_bucket') String? responseTimeBucket,
    @JsonKey(name: 'last_active_bucket') required String lastActiveBucket,
  }) = _ListingOwner;

  factory ListingOwner.fromJson(Map<String, dynamic> json) => _$ListingOwnerFromJson(json);
}

@freezed
class Listing with _$Listing {
  const factory Listing({
    required int id,
    required String state,
    @JsonKey(name: 'stale_state') String? staleState,
    required String title,
    required String description,
    required double price,
    required String city,
    required String district,
    @JsonKey(name: 'last_confirmed_at') required DateTime lastConfirmedAt,
    required ListingOwner owner,
    @JsonKey(name: 'car_details') required CarDetail carDetails,
    @Default(<ListingPhoto>[]) List<ListingPhoto> photos,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);
}
