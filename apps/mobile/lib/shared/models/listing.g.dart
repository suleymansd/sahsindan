// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CarDetailImpl _$$CarDetailImplFromJson(Map<String, dynamic> json) =>
    _$CarDetailImpl(
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      mileage: (json['mileage'] as num).toInt(),
      transmission: json['transmission'] as String,
      fuel: json['fuel'] as String,
      color: json['color'] as String,
      vinOptional: json['vin_optional'] as String?,
    );

Map<String, dynamic> _$$CarDetailImplToJson(_$CarDetailImpl instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'model': instance.model,
      'year': instance.year,
      'mileage': instance.mileage,
      'transmission': instance.transmission,
      'fuel': instance.fuel,
      'color': instance.color,
      'vin_optional': instance.vinOptional,
    };

_$ListingPhotoImpl _$$ListingPhotoImplFromJson(Map<String, dynamic> json) =>
    _$ListingPhotoImpl(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
    );

Map<String, dynamic> _$$ListingPhotoImplToJson(_$ListingPhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'sort_order': instance.sortOrder,
    };

_$ListingOwnerImpl _$$ListingOwnerImplFromJson(Map<String, dynamic> json) =>
    _$ListingOwnerImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      trustScore: (json['trust_score'] as num).toInt(),
      responseTimeBucket: json['response_time_bucket'] as String?,
      lastActiveBucket: json['last_active_bucket'] as String,
    );

Map<String, dynamic> _$$ListingOwnerImplToJson(_$ListingOwnerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trust_score': instance.trustScore,
      'response_time_bucket': instance.responseTimeBucket,
      'last_active_bucket': instance.lastActiveBucket,
    };

_$ListingImpl _$$ListingImplFromJson(Map<String, dynamic> json) =>
    _$ListingImpl(
      id: (json['id'] as num).toInt(),
      state: json['state'] as String,
      staleState: json['stale_state'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      city: json['city'] as String,
      district: json['district'] as String,
      lastConfirmedAt: DateTime.parse(json['last_confirmed_at'] as String),
      owner: ListingOwner.fromJson(json['owner'] as Map<String, dynamic>),
      carDetails:
          CarDetail.fromJson(json['car_details'] as Map<String, dynamic>),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => ListingPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ListingPhoto>[],
    );

Map<String, dynamic> _$$ListingImplToJson(_$ListingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'state': instance.state,
      'stale_state': instance.staleState,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'city': instance.city,
      'district': instance.district,
      'last_confirmed_at': instance.lastConfirmedAt.toIso8601String(),
      'owner': instance.owner,
      'car_details': instance.carDetails,
      'photos': instance.photos,
    };
