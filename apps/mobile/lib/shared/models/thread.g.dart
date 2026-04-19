// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThreadListingSummaryImpl _$$ThreadListingSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$ThreadListingSummaryImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      photoUrl: json['photo_url'] as String?,
    );

Map<String, dynamic> _$$ThreadListingSummaryImplToJson(
        _$ThreadListingSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'photo_url': instance.photoUrl,
    };

_$ThreadOtherUserImpl _$$ThreadOtherUserImplFromJson(
        Map<String, dynamic> json) =>
    _$ThreadOtherUserImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      trustScore: (json['trust_score'] as num).toInt(),
      responseTimeBucket: json['response_time_bucket'] as String?,
      lastActiveBucket: json['last_active_bucket'] as String,
    );

Map<String, dynamic> _$$ThreadOtherUserImplToJson(
        _$ThreadOtherUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trust_score': instance.trustScore,
      'response_time_bucket': instance.responseTimeBucket,
      'last_active_bucket': instance.lastActiveBucket,
    };

_$ThreadMessageImpl _$$ThreadMessageImplFromJson(Map<String, dynamic> json) =>
    _$ThreadMessageImpl(
      id: (json['id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      body: json['body'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$$ThreadMessageImplToJson(_$ThreadMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'body': instance.body,
      'created_at': instance.createdAt?.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
    };

_$ThreadImpl _$$ThreadImplFromJson(Map<String, dynamic> json) => _$ThreadImpl(
      id: (json['id'] as num).toInt(),
      listingId: (json['listing_id'] as num).toInt(),
      buyerId: (json['buyer_id'] as num).toInt(),
      sellerId: (json['seller_id'] as num).toInt(),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      lastMessageBody: json['last_message_body'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt(),
      listing: json['listing'] == null
          ? null
          : ThreadListingSummary.fromJson(
              json['listing'] as Map<String, dynamic>),
      otherUser: json['other_user'] == null
          ? null
          : ThreadOtherUser.fromJson(
              json['other_user'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ThreadMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ThreadMessage>[],
    );

Map<String, dynamic> _$$ThreadImplToJson(_$ThreadImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listing_id': instance.listingId,
      'buyer_id': instance.buyerId,
      'seller_id': instance.sellerId,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'last_message_body': instance.lastMessageBody,
      'unread_count': instance.unreadCount,
      'listing': instance.listing,
      'other_user': instance.otherUser,
      'messages': instance.messages,
    };
