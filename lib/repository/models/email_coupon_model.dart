// DTOs for the Gmail coupon scrape service
// (https://link-account.shareperks.in).
//
// Primary product endpoints:
// - GET /api/accounts/by-account/{accountId}
// - GET /api/accounts/by-account/{accountId}/coupons

class EmailCoupon {
  EmailCoupon({
    required this.id,
    this.source,
    this.brand,
    this.offer,
    this.couponCode,
    this.pin,
    this.validTill,
    this.eligibility,
    this.notes,
    this.extractedAt,
    this.email,
    this.gmailUser,
  });

  final String id;
  final String? source;
  final String? brand;
  final String? offer;
  final String? couponCode;
  final String? pin;
  final String? validTill;
  final String? eligibility;
  final String? notes;
  final String? extractedAt;
  final EmailCouponEmailRef? email;
  final EmailCouponGmailUserRef? gmailUser;

  factory EmailCoupon.fromJson(Map<String, dynamic> json) {
    return EmailCoupon(
      id: (json['id'] ?? '').toString(),
      source: json['source'] as String?,
      brand: json['brand'] as String?,
      offer: json['offer'] as String?,
      couponCode: json['coupon_code'] as String?,
      pin: json['pin'] as String?,
      validTill: json['valid_till'] as String?,
      eligibility: json['eligibility'] as String?,
      notes: json['notes'] as String?,
      extractedAt: json['extracted_at'] as String?,
      email: json['email'] is Map<String, dynamic>
          ? EmailCouponEmailRef.fromJson(json['email'] as Map<String, dynamic>)
          : null,
      gmailUser: json['gmail_user'] is Map<String, dynamic>
          ? EmailCouponGmailUserRef.fromJson(
              json['gmail_user'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Prefer brand, fall back to source for the card title.
  String get displayTitle {
    final b = brand?.trim();
    if (b != null && b.isNotEmpty) return b;
    final s = source?.trim();
    if (s != null && s.isNotEmpty) return s;
    return 'Coupon';
  }

  String get displaySubtitle {
    final o = offer?.trim();
    if (o != null && o.isNotEmpty) return o;
    final s = source?.trim();
    if (s != null && s.isNotEmpty && s != displayTitle) return s;
    return '';
  }
}

class EmailCouponEmailRef {
  EmailCouponEmailRef({
    this.id,
    this.subject,
    this.from,
    this.receivedAt,
  });

  final String? id;
  final String? subject;
  final String? from;
  final String? receivedAt;

  factory EmailCouponEmailRef.fromJson(Map<String, dynamic> json) {
    return EmailCouponEmailRef(
      id: json['id']?.toString(),
      subject: json['subject'] as String?,
      from: json['from'] as String?,
      receivedAt: json['received_at'] as String?,
    );
  }
}

class EmailCouponGmailUserRef {
  EmailCouponGmailUserRef({
    this.id,
    this.email,
    this.accountId,
  });

  final String? id;
  final String? email;
  final String? accountId;

  factory EmailCouponGmailUserRef.fromJson(Map<String, dynamic> json) {
    return EmailCouponGmailUserRef(
      id: json['id']?.toString(),
      email: json['email'] as String?,
      accountId: json['account_id'] as String?,
    );
  }
}

class PaginatedEmailCouponsResponse {
  PaginatedEmailCouponsResponse({
    this.accountId,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
    required this.coupons,
  });

  final String? accountId;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;
  final List<EmailCoupon> coupons;

  factory PaginatedEmailCouponsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['coupons'];
    return PaginatedEmailCouponsResponse(
      accountId: json['accountId']?.toString(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] == true,
      coupons: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => EmailCoupon.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <EmailCoupon>[],
    );
  }
}

class LinkedGmailAccount {
  LinkedGmailAccount({
    required this.id,
    this.accountId,
    required this.email,
    this.name,
    this.picture,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? accountId;
  final String email;
  final String? name;
  final String? picture;
  final String? createdAt;
  final String? updatedAt;

  factory LinkedGmailAccount.fromJson(Map<String, dynamic> json) {
    return LinkedGmailAccount(
      id: (json['id'] ?? '').toString(),
      accountId: json['accountId']?.toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class GmailAccountsByAccountIdResponse {
  GmailAccountsByAccountIdResponse({
    required this.accountId,
    required this.count,
    required this.accounts,
  });

  final String accountId;
  final int count;
  final List<LinkedGmailAccount> accounts;

  factory GmailAccountsByAccountIdResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['accounts'];
    return GmailAccountsByAccountIdResponse(
      accountId: (json['accountId'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      accounts: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      LinkedGmailAccount.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <LinkedGmailAccount>[],
    );
  }

  bool get isConnected => count > 0 || accounts.isNotEmpty;
}
