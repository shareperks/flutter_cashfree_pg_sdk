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
    this.name,
    this.offer,
    this.description,
    this.image,
    this.price,
    this.maximumDiscount,
    this.couponCode,
    this.pin,
    this.redeemUrl,
    this.validFrom,
    this.validTill,
    this.eligibility,
    this.notes,
    this.extractedAt,
    this.used = false,
    this.usedAt,
    this.email,
    this.gmailUser,
  });

  final String id;
  final String? source;
  final String? brand;
  final String? name;
  final String? offer;
  final String? description;
  final String? image;
  final String? price;
  final String? maximumDiscount;
  final String? couponCode;
  final String? pin;
  final String? redeemUrl;
  final String? validFrom;
  final String? validTill;
  final String? eligibility;
  final String? notes;
  final String? extractedAt;
  final bool used;
  final String? usedAt;
  final EmailCouponEmailRef? email;
  final EmailCouponGmailUserRef? gmailUser;

  factory EmailCoupon.fromJson(Map<String, dynamic> json) {
    return EmailCoupon(
      id: (json['id'] ?? '').toString(),
      source: json['source'] as String?,
      brand: json['brand'] as String?,
      name: json['name'] as String?,
      offer: json['offer'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      price: json['price'] as String?,
      maximumDiscount: json['maximum_discount'] as String?,
      couponCode: json['coupon_code'] as String?,
      pin: json['pin'] as String?,
      redeemUrl: (json['redeem_url'] ?? json['redeemUrl']) as String?,
      validFrom: json['valid_from'] as String?,
      validTill: json['valid_till'] as String?,
      eligibility: json['eligibility'] as String?,
      notes: json['notes'] as String?,
      extractedAt: json['extracted_at'] as String?,
      used: json['used'] == true,
      usedAt: (json['used_at'] ?? json['usedAt'])?.toString(),
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

  EmailCoupon copyWith({
    bool? used,
    String? usedAt,
    bool clearUsedAt = false,
  }) {
    return EmailCoupon(
      id: id,
      source: source,
      brand: brand,
      name: name,
      offer: offer,
      description: description,
      image: image,
      price: price,
      maximumDiscount: maximumDiscount,
      couponCode: couponCode,
      pin: pin,
      redeemUrl: redeemUrl,
      validFrom: validFrom,
      validTill: validTill,
      eligibility: eligibility,
      notes: notes,
      extractedAt: extractedAt,
      used: used ?? this.used,
      usedAt: clearUsedAt ? null : (usedAt ?? this.usedAt),
      email: email,
      gmailUser: gmailUser,
    );
  }

  /// Prefer offer name, then brand, then source.
  String get displayTitle {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final b = brand?.trim();
    if (b != null && b.isNotEmpty) return b;
    final s = source?.trim();
    if (s != null && s.isNotEmpty) return s;
    return 'Coupon';
  }

  /// Brand line under the title when title is the offer name.
  String get displayBrand {
    final b = brand?.trim();
    if (b == null || b.isEmpty) return '';
    if (b == displayTitle) return '';
    return b;
  }

  String get displaySubtitle {
    final o = offer?.trim();
    if (o != null && o.isNotEmpty) return o;
    final d = maximumDiscount?.trim();
    if (d != null && d.isNotEmpty) return d;
    final s = source?.trim();
    if (s != null && s.isNotEmpty && s != displayTitle) return s;
    return '';
  }

  /// Best available image — coupon image, else first email image.
  /// Prefers raster over SVG when choosing among email image URLs.
  /// Skips empty / cid: / non-http URLs that cannot be loaded in-app.
  String? get displayImage {
    bool usable(String? raw) {
      final t = raw?.trim() ?? '';
      if (t.isEmpty) return false;
      final lower = t.toLowerCase();
      if (lower.startsWith('cid:')) return false;
      return lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower.startsWith('//') ||
          lower.startsWith('data:image');
    }

    final img = image?.trim();
    if (usable(img)) return img;

    final urls = email?.imageUrls;
    if (urls == null || urls.isEmpty) return null;

    String? firstSvg;
    for (final raw in urls) {
      final t = raw.trim();
      if (!usable(t)) continue;
      if (_looksLikeSvgUrl(t)) {
        firstSvg ??= t;
        continue;
      }
      return t;
    }
    return firstSvg;
  }

  String get validityLabel {
    final from = validFrom?.trim();
    final till = validTill?.trim();
    if (from != null &&
        from.isNotEmpty &&
        till != null &&
        till.isNotEmpty) {
      return '$from → $till';
    }
    if (till != null && till.isNotEmpty) return 'Till $till';
    if (from != null && from.isNotEmpty) return 'From $from';
    return '';
  }
}

/// Filter for `GET .../coupons?used=...`
enum EmailCouponUsedFilter {
  all,
  unused,
  used;

  /// Query value for by-account coupons API (`used` / `unused`), or null.
  String? get queryValue {
    switch (this) {
      case EmailCouponUsedFilter.all:
        return null;
      case EmailCouponUsedFilter.unused:
        return 'unused';
      case EmailCouponUsedFilter.used:
        return 'used';
    }
  }

  String get label {
    switch (this) {
      case EmailCouponUsedFilter.all:
        return 'All';
      case EmailCouponUsedFilter.unused:
        return 'Unused';
      case EmailCouponUsedFilter.used:
        return 'Used';
    }
  }
}

bool _looksLikeSvgUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  final path = (uri?.path ?? url).toLowerCase();
  if (path.endsWith('.svg')) return true;
  final lower = url.toLowerCase();
  return lower.contains('image/svg') || lower.contains('format=svg');
}

class EmailCouponEmailRef {
  EmailCouponEmailRef({
    this.id,
    this.subject,
    this.from,
    this.receivedAt,
    this.imageUrls = const <String>[],
  });

  final String? id;
  final String? subject;
  final String? from;
  final String? receivedAt;
  final List<String> imageUrls;

  factory EmailCouponEmailRef.fromJson(Map<String, dynamic> json) {
    final rawImages = json['image_urls'];
    return EmailCouponEmailRef(
      id: json['id']?.toString(),
      subject: json['subject'] as String?,
      from: json['from'] as String?,
      receivedAt: json['received_at'] as String?,
      imageUrls: rawImages is List
          ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const <String>[],
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

/// Response from `DELETE /api/accounts/{id}`.
class GmailDisconnectResponse {
  GmailDisconnectResponse({
    required this.ok,
    this.disconnected,
  });

  final bool ok;
  final GmailDisconnectedAccount? disconnected;

  factory GmailDisconnectResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['disconnected'];
    return GmailDisconnectResponse(
      ok: json['ok'] == true,
      disconnected: raw is Map
          ? GmailDisconnectedAccount.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
  }
}

class GmailDisconnectedAccount {
  GmailDisconnectedAccount({
    required this.id,
    required this.email,
    this.accountId,
    this.deletedCoupons,
    this.deletedEmails,
  });

  final String id;
  final String email;
  final String? accountId;
  final int? deletedCoupons;
  final int? deletedEmails;

  factory GmailDisconnectedAccount.fromJson(Map<String, dynamic> json) {
    final deleted = json['deleted'];
    final deletedMap = deleted is Map
        ? Map<String, dynamic>.from(deleted)
        : const <String, dynamic>{};
    return GmailDisconnectedAccount(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      accountId: json['accountId']?.toString(),
      deletedCoupons: (deletedMap['coupons'] as num?)?.toInt(),
      deletedEmails: (deletedMap['emails'] as num?)?.toInt(),
    );
  }
}
