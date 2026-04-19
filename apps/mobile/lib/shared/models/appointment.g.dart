// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppointmentImpl _$$AppointmentImplFromJson(Map<String, dynamic> json) =>
    _$AppointmentImpl(
      id: (json['id'] as num).toInt(),
      listingId: (json['listing_id'] as num).toInt(),
      buyerId: (json['buyer_id'] as num).toInt(),
      sellerId: (json['seller_id'] as num).toInt(),
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      location: json['location'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$AppointmentImplToJson(_$AppointmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listing_id': instance.listingId,
      'buyer_id': instance.buyerId,
      'seller_id': instance.sellerId,
      'status': instance.status,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'location': instance.location,
      'notes': instance.notes,
    };
