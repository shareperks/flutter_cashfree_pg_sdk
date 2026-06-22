/// DTOs for the notifications API mounted on the listing service.
///
/// Endpoints (all JWT-protected):
/// - `GET    /notifications`             — paginated list (cursor by createAt)
/// - `GET    /notifications/unread-count` — `{ unreadCount, lastSeenAt }`
/// - `GET    /notifications/:id`         — single
/// - `POST   /notifications/mark-all-read`
/// - `DELETE /notifications/:id`
/// - `DELETE /notifications`
///
/// Read-state is tracked server-side in Redis as a single `lastSeenAt` per
/// user; an item is `isRead` iff `createdAt <= lastSeenAt`. There is no
/// per-item read receipt.
library;

/// One notification card. Field shape mirrors the server response 1:1.
///
/// `category` is one of `PERKS | HOW_TO_CLAIM | BENEFIT | REFERRALS`. We
/// keep it as a `String` to stay forward-compatible with future server-side
/// enum additions (mapping is done in the UI layer).
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.category,
    required this.isRead,
    this.screen,
    this.rewardId,
    this.createdAt,
    this.createdAtFormatted,
    this.timeFormatted,
  });

  final String id;
  final String title;
  final String description;
  final String image;
  final String type;
  final String category;
  final String? screen;
  final String? rewardId;
  final bool isRead;

  /// Raw ISO timestamp (`createdAt`) for cursor pagination. The server's
  /// `nextCursor` is the `createdAt` of the last item it returned.
  final DateTime? createdAt;

  /// Pre-formatted by the server, e.g. `"10 Jun 2026"`.
  final String? createdAtFormatted;

  /// Pre-formatted by the server, e.g. `"9:42 PM"`.
  final String? timeFormatted;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      image: (json['image'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      screen: json['screen'] as String?,
      rewardId: json['rewardId'] as String?,
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      createdAtFormatted: json['createdAtFormatted'] as String?,
      timeFormatted: json['timeFormatted'] as String?,
    );
  }

  /// Convenience: derive a label like `"10 Jun 2026 · 9:42 PM"` falling back
  /// gracefully when only one of the formatted fields is present.
  String get displayTimestamp {
    final d = createdAtFormatted?.trim();
    final t = timeFormatted?.trim();
    if ((d?.isNotEmpty ?? false) && (t?.isNotEmpty ?? false)) return '$d · $t';
    if (d?.isNotEmpty ?? false) return d!;
    if (t?.isNotEmpty ?? false) return t!;
    return '';
  }
}

class NotificationListData {
  NotificationListData({
    required this.items,
    this.nextCursor,
    this.unreadCount = 0,
    this.lastSeenAt,
  });

  final List<AppNotification> items;

  /// ISO timestamp; pass back to `GET /notifications?cursor=…` for the next
  /// page. `null` means there are no more items after this page.
  final String? nextCursor;

  final int unreadCount;
  final DateTime? lastSeenAt;

  factory NotificationListData.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList()
        : <AppNotification>[];

    return NotificationListData(
      items: items,
      nextCursor: json['nextCursor'] as String?,
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
      lastSeenAt: json['lastSeenAt'] is String
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
    );
  }
}

class NotificationListEnvelope {
  NotificationListEnvelope({required this.success, this.data, this.message});

  final bool success;
  final NotificationListData? data;
  final String? message;

  factory NotificationListEnvelope.fromJson(Map<String, dynamic> json) {
    return NotificationListEnvelope(
      success: json['success'] == true,
      data: json['data'] is Map<String, dynamic>
          ? NotificationListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}

class UnreadCountData {
  const UnreadCountData({required this.unreadCount, this.lastSeenAt});

  final int unreadCount;
  final DateTime? lastSeenAt;

  static const empty = UnreadCountData(unreadCount: 0);

  factory UnreadCountData.fromJson(Map<String, dynamic> json) {
    return UnreadCountData(
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
      lastSeenAt: json['lastSeenAt'] is String
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
    );
  }
}
