import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/notification_model.dart';
import 'package:shareperks/repository/network.dart';

/// Server-defined enum string for the `category` filter.
///
/// Kept as a plain set of constants (not a Dart enum) so we can pass them
/// directly as query params and stay forward-compatible with new categories.
class NotificationCategory {
  const NotificationCategory._();

  static const String perks = 'PERKS';
  static const String howToClaim = 'HOW_TO_CLAIM';
  static const String benefit = 'BENEFIT';
  static const String referrals = 'REFERRALS';

  static const Set<String> values = <String>{
    perks,
    howToClaim,
    benefit,
    referrals,
  };
}

/// Thin client over the listing service notifications API. All endpoints
/// require the JWT (attached automatically by the existing Dio interceptor).
class NotificationService {
  NotificationService._();

  static final Dio _dio = createDio(Host.listingUrl);

  /// `GET /notifications`
  ///
  /// Cursor pagination by `createdAt`: pass back the previous response's
  /// `nextCursor` to fetch older items.
  static Future<NotificationListData> list({
    int? limit,
    String? cursor,
    String? category,
    String? type,
    bool? unreadOnly,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: <String, dynamic>{
        'limit': ?limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (category != null && category.isNotEmpty) 'category': category,
        if (type != null && type.isNotEmpty) 'type': type,
        if (unreadOnly == true) 'unreadOnly': 1,
      },
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Notifications: empty response body');
    }
    final envelope = NotificationListEnvelope.fromJson(body);
    if (!envelope.success || envelope.data == null) {
      throw StateError(envelope.message ?? 'Could not load notifications.');
    }
    return envelope.data!;
  }

  /// `GET /notifications/unread-count` — cheap badge endpoint.
  ///
  /// Returns [UnreadCountData.empty] on transport / shape errors so a
  /// flaky network never breaks the bell badge.
  static Future<UnreadCountData> getUnreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      final body = response.data;
      if (body == null) return UnreadCountData.empty;
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return UnreadCountData.fromJson(data);
      }
      // Defensive: some servers may flatten the envelope.
      return UnreadCountData.fromJson(body);
    } catch (_) {
      return UnreadCountData.empty;
    }
  }

  /// `POST /notifications/mark-all-read` — bumps `lastSeenAt` to `now`.
  static Future<void> markAllRead() async {
    await _dio.post<Map<String, dynamic>>('/notifications/mark-all-read');
  }

  /// `DELETE /notifications/:id` — owner-scoped on the server.
  static Future<void> deleteOne(String id) async {
    await _dio.delete<Map<String, dynamic>>('/notifications/$id');
  }

  /// `DELETE /notifications` — clears every notification for the user.
  static Future<void> clearAll() async {
    await _dio.delete<Map<String, dynamic>>('/notifications');
  }
}
