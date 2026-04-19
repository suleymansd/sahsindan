// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread.freezed.dart';
part 'thread.g.dart';

@freezed
class ThreadListingSummary with _$ThreadListingSummary {
  const factory ThreadListingSummary({
    required int id,
    String? title,
    @JsonKey(name: 'photo_url') String? photoUrl,
  }) = _ThreadListingSummary;

  factory ThreadListingSummary.fromJson(Map<String, dynamic> json) => _$ThreadListingSummaryFromJson(json);
}

@freezed
class ThreadOtherUser with _$ThreadOtherUser {
  const factory ThreadOtherUser({
    required int id,
    required String name,
    @JsonKey(name: 'trust_score') required int trustScore,
    @JsonKey(name: 'response_time_bucket') String? responseTimeBucket,
    @JsonKey(name: 'last_active_bucket') required String lastActiveBucket,
  }) = _ThreadOtherUser;

  factory ThreadOtherUser.fromJson(Map<String, dynamic> json) => _$ThreadOtherUserFromJson(json);
}

@freezed
class ThreadMessage with _$ThreadMessage {
  const factory ThreadMessage({
    required int id,
    @JsonKey(name: 'sender_id') required int senderId,
    required String body,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'read_at') DateTime? readAt,
  }) = _ThreadMessage;

  factory ThreadMessage.fromJson(Map<String, dynamic> json) => _$ThreadMessageFromJson(json);
}

@freezed
class Thread with _$Thread {
  const factory Thread({
    required int id,
    @JsonKey(name: 'listing_id') required int listingId,
    @JsonKey(name: 'buyer_id') required int buyerId,
    @JsonKey(name: 'seller_id') required int sellerId,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'last_message_body') String? lastMessageBody,
    @JsonKey(name: 'unread_count') int? unreadCount,
    ThreadListingSummary? listing,
    @JsonKey(name: 'other_user') ThreadOtherUser? otherUser,
    @Default(<ThreadMessage>[]) List<ThreadMessage> messages,
  }) = _Thread;

  factory Thread.fromJson(Map<String, dynamic> json) => _$ThreadFromJson(json);
}
