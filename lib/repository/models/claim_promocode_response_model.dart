/// Response DTO for `POST /rewards/promocode/:id/claim`.
///
/// Allocates a promo code from an offer's pool to the authenticated user.
/// HTTP 201 on first claim, HTTP 200 with `alreadyClaimed: true` on re-claim.
class ClaimPromocodeResponse {
  ClaimPromocodeResponse({
    this.claimedId,
    this.rewardId,
    this.code,
    this.isEligible,
    this.isBrokerageEligible,
    this.allowFor,
    this.assignedAt,
    this.rewardType,
    this.discount,
    this.term,
    this.alreadyClaimed,
    this.info,
  });

  final String? claimedId;
  final String? rewardId;
  final String? code;
  final bool? isEligible;

  /// Mid tier: broker connected with holdings, but not fully eligible.
  final bool? isBrokerageEligible;

  /// `WITH_HOLDINGS` (fully eligible) or `NON_HOLDINGS` (everyone else).
  /// Mid-tier still uses the non-holdings pool until a third pool exists.
  final String? allowFor;

  /// ISO 8601 timestamp.
  final String? assignedAt;

  /// e.g. `PERCENTAGE`, `FLAT`, etc.
  final String? rewardType;

  /// Numeric discount (interpretation depends on [rewardType]).
  final num? discount;

  /// Human-readable label such as `"10% OFF"`.
  final String? term;

  /// `true` when the user already had this code allocated and the call was
  /// idempotent.
  final bool? alreadyClaimed;

  /// Brand / offer metadata for success-state UI.
  final ClaimPromocodeInfo? info;

  factory ClaimPromocodeResponse.fromJson(Map<String, dynamic> json) {
    final infoRaw = json['info'];
    return ClaimPromocodeResponse(
      claimedId: json['claimedId'] as String?,
      rewardId: json['rewardId'] as String?,
      code: json['code'] as String?,
      isEligible: json['isEligible'] as bool?,
      isBrokerageEligible: json['isBrokerageEligible'] as bool?,
      allowFor: json['allowFor'] as String?,
      assignedAt: json['assignedAt'] as String?,
      rewardType: json['rewardType'] as String?,
      discount: json['discount'] as num?,
      term: json['term'] as String?,
      alreadyClaimed: json['alreadyClaimed'] as bool?,
      info: infoRaw is Map<String, dynamic>
          ? ClaimPromocodeInfo.fromJson(infoRaw)
          : null,
    );
  }
}

class ClaimPromocodeInfo {
  ClaimPromocodeInfo({
    this.rewardId,
    this.name,
    this.brandId,
    this.brandName,
    this.image,
    this.banner,
    this.categoryName,
  });

  final String? rewardId;
  final String? name;
  final String? brandId;
  final String? brandName;
  final String? image;
  final String? banner;
  final String? categoryName;

  factory ClaimPromocodeInfo.fromJson(Map<String, dynamic> json) {
    return ClaimPromocodeInfo(
      rewardId: json['rewardId'] as String?,
      name: json['name'] as String?,
      brandId: json['brandId'] as String?,
      brandName: json['brandName'] as String?,
      image: json['image'] as String?,
      banner: json['banner'] as String?,
      categoryName: json['categoryName'] as String?,
    );
  }
}

/// `{ success, data, message }` envelope returned by the data_service claim
/// route.
class ClaimPromocodeEnvelope {
  ClaimPromocodeEnvelope({required this.success, this.data, this.message});

  final bool success;
  final ClaimPromocodeResponse? data;
  final String? message;

  factory ClaimPromocodeEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return ClaimPromocodeEnvelope(
      success: json['success'] as bool? ?? false,
      data: raw is Map<String, dynamic>
          ? ClaimPromocodeResponse.fromJson(raw)
          : null,
      message: json['message'] as String?,
    );
  }
}
