import 'package:dio/dio.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:shareperks/repository/network.dart';

/// Client for the Gmail coupon scrape service.
///
/// APIs are keyed by SharePerks [accountId] (the app user id).
class GmailCouponService {
  GmailCouponService._();

  static final Dio _dio = createDio(Host.linkAccountUrl);

  /// OAuth start URL — open in a system browser / in-app browser sheet.
  static String connectGoogleUrl(String accountId) {
    final uri = Uri.parse('${Host.linkAccountUrl}/auth/google').replace(
      queryParameters: {'accountId': accountId},
    );
    return uri.toString();
  }

  /// Resolves the SharePerks user id used as `accountId` for this service.
  static String? resolveAccountId({String? fromUserProvider}) {
    final fromProvider = fromUserProvider?.trim();
    if (fromProvider != null && fromProvider.isNotEmpty) return fromProvider;
    final stored = LocalStorage.getString('userId')?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  /// `GET /api/accounts/by-account/{accountId}`
  static Future<GmailAccountsByAccountIdResponse> listAccounts(
    String accountId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/accounts/by-account/$accountId',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Gmail accounts: empty response body');
    }
    return GmailAccountsByAccountIdResponse.fromJson(body);
  }

  /// `GET /api/accounts/by-account/{accountId}/coupons`
  static Future<PaginatedEmailCouponsResponse> listCoupons(
    String accountId, {
    int page = 1,
    int limit = 20,
    String? brand,
    String? q,
    EmailCouponUsedFilter usedFilter = EmailCouponUsedFilter.all,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/accounts/by-account/$accountId/coupons',
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (usedFilter.queryValue != null) 'used': usedFilter.queryValue,
      },
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Email coupons: empty response body');
    }
    return PaginatedEmailCouponsResponse.fromJson(body);
  }

  /// `PATCH /api/coupons/{id}/used` with `{ "used": true|false }`.
  static Future<EmailCoupon> setCouponUsed(
    String couponId, {
    required bool used,
    EmailCoupon? current,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/coupons/$couponId/used',
      data: <String, dynamic>{'used': used},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Mark coupon used: empty response body');
    }

    final nested = body['coupon'];
    if (nested is Map) {
      return EmailCoupon.fromJson(Map<String, dynamic>.from(nested));
    }
    if (body.containsKey('coupon_code') ||
        body.containsKey('brand') ||
        body.containsKey('source') ||
        body.containsKey('name')) {
      return EmailCoupon.fromJson(body);
    }

    final nextUsed = body['used'] == true;
    final nextUsedAt = (body['used_at'] ?? body['usedAt'])?.toString();
    if (current != null) {
      return current.copyWith(
        used: nextUsed,
        usedAt: nextUsedAt,
        clearUsedAt: !nextUsed,
      );
    }

    return EmailCoupon(
      id: couponId,
      used: nextUsed,
      usedAt: nextUsedAt,
    );
  }

  /// `DELETE /api/accounts/{id}` — [gmailConnectionId] is the linked Gmail
  /// user id (`LinkedGmailAccount.id`), not the SharePerks `accountId`.
  static Future<GmailDisconnectResponse> disconnectAccount(
    String gmailConnectionId,
  ) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/accounts/$gmailConnectionId',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Gmail disconnect: empty response body');
    }
    return GmailDisconnectResponse.fromJson(body);
  }
}
