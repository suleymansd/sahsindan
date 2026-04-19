// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment.freezed.dart';
part 'appointment.g.dart';

@freezed
class Appointment with _$Appointment {
  const factory Appointment({
    required int id,
    @JsonKey(name: 'listing_id') required int listingId,
    @JsonKey(name: 'buyer_id') required int buyerId,
    @JsonKey(name: 'seller_id') required int sellerId,
    required String status,
    @JsonKey(name: 'scheduled_at') required DateTime scheduledAt,
    required String location,
    String? notes,
  }) = _Appointment;

  factory Appointment.fromJson(Map<String, dynamic> json) => _$AppointmentFromJson(json);
}
