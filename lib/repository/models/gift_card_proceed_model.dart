/// Body for `POST /payment/giftcard/proceed`.
class GiftCardProceedRequest {
  const GiftCardProceedRequest({
    required this.payAmount,
    required this.rewardAmount,
    required this.creditId,
    required this.eligible,
    this.isBrokerageEligible = false,
    this.journeyId,
    this.couponCode,
  });

  /// Dual contract for backward compatibility:
  /// - **No coupon:** client SharePerks-discounted payable (older behavior).
  /// - **With [couponCode]:** same SharePerks-discounted payable as the coupon
  ///   order base; server applies coupon on top and returns gateway `amount` /
  ///   optional `pricing`.
  final double payAmount;

  /// Gift-card face / entered amount.
  final double rewardAmount;
  final String creditId;

  /// Fully eligible (max holder rate). Mid-tier users remain `false`.
  /// Used as a hint; without coupon the server trusts client [payAmount].
  final bool eligible;

  /// Mid tier: broker connected with holdings, not fully eligible.
  final bool isBrokerageEligible;
  final String? journeyId;

  /// When set, server applies the coupon on [payAmount] (SharePerks payable).
  /// Omit for the legacy path (charge client [payAmount] as-is).
  final String? couponCode;

  Map<String, dynamic> toJson() => {
    'payAmount': payAmount,
    'rewardAmount': rewardAmount,
    'creditId': creditId,
    'eligible': eligible,
    'isBrokerageEligible': isBrokerageEligible,
    if (journeyId != null) 'journey_id': journeyId,
    if (couponCode != null && couponCode!.trim().isNotEmpty)
      'couponCode': couponCode!.trim().toUpperCase(),
  };
}

class GiftCardProceedPricing {
  const GiftCardProceedPricing({
    required this.faceAmount,
    required this.couponDiscount,
    required this.sharePerksDiscount,
    required this.chargeAmount,
  });

  final double faceAmount;
  final double couponDiscount;
  final double sharePerksDiscount;
  final double chargeAmount;

  factory GiftCardProceedPricing.fromJson(Map<String, dynamic> json) {
    double readAmount(String key) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return GiftCardProceedPricing(
      faceAmount: readAmount('faceAmount'),
      couponDiscount: readAmount('couponDiscount'),
      sharePerksDiscount: readAmount('sharePerksDiscount'),
      chargeAmount: readAmount('chargeAmount'),
    );
  }
}

class GiftCardProceedCoupon {
  const GiftCardProceedCoupon({
    required this.code,
    required this.discountApplied,
    required this.payableAfterDiscount,
  });

  final String code;
  final double discountApplied;
  final double payableAfterDiscount;

  factory GiftCardProceedCoupon.fromJson(Map<String, dynamic> json) {
    double readAmount(String key) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return GiftCardProceedCoupon(
      code: json['code']?.toString() ?? '',
      discountApplied: readAmount('discountApplied'),
      payableAfterDiscount: readAmount('payableAfterDiscount'),
    );
  }
}

/// Direct `200` body from `POST /payment/giftcard/proceed`.
class GiftCardProceedResponse {
  const GiftCardProceedResponse({
    required this.success,
    required this.message,
    required this.orderId,
    required this.razorpayOrderId,
    required this.amountPaise,
    this.keyId,
    this.gateway,
    this.currency,
    this.pricing,
    this.coupon,
  });

  final bool success;
  final String message;
  final String orderId;
  final String razorpayOrderId;

  /// Amount in paise for Razorpay Checkout.
  final int amountPaise;
  final String? keyId;
  final String? gateway;
  final String? currency;
  final GiftCardProceedPricing? pricing;
  final GiftCardProceedCoupon? coupon;

  factory GiftCardProceedResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final amountRaw = data['amount'];
    final amountPaise = amountRaw is int
        ? amountRaw
        : amountRaw is num
        ? amountRaw.round()
        : int.tryParse(amountRaw?.toString() ?? '') ?? 0;

    return GiftCardProceedResponse(
      success: data['success'] as bool? ?? json['success'] as bool? ?? false,
      message: (data['message'] ?? json['message'])?.toString() ?? '',
      orderId: (data['orderId'] ?? data['order_id'])?.toString() ?? '',
      razorpayOrderId:
          (data['razorpayOrderId'] ?? data['razorpay_order_id'])?.toString() ??
          '',
      amountPaise: amountPaise,
      keyId: (data['keyId'] ?? data['key_id'])?.toString(),
      gateway: data['gateway']?.toString(),
      currency: data['currency']?.toString(),
      pricing: data['pricing'] is Map
          ? GiftCardProceedPricing.fromJson(
              Map<String, dynamic>.from(data['pricing'] as Map),
            )
          : null,
      coupon: data['coupon'] is Map
          ? GiftCardProceedCoupon.fromJson(
              Map<String, dynamic>.from(data['coupon'] as Map),
            )
          : null,
    );
  }
}
