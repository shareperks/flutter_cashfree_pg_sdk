import 'package:shareperks/repository/models/home_common_models.dart';

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
    this.useWallet,
    this.useFullWallet,
    this.walletAmount,
  });

  /// Dual contract:
  /// - **No coupon:** SharePerks-discounted payable (legacy gateway-only).
  /// - **With [couponCode]:** face amount; server quotes
  ///   face → SharePerks → wallet → coupon → gateway.
  final double payAmount;

  /// Gift-card face / entered amount.
  final double rewardAmount;
  final String creditId;

  /// Fully eligible (max holder rate). Hint only when coupon path applies.
  final bool eligible;

  /// Mid tier: broker connected with holdings, not fully eligible.
  final bool isBrokerageEligible;
  final String? journeyId;

  /// When set, server quotes face → SharePerks → wallet → coupon.
  final String? couponCode;

  /// Opt into wallet tender. Server caps by balance and payable.
  final bool? useWallet;

  /// Prefer using as much wallet balance as allowed.
  final bool? useFullWallet;

  /// Optional explicit wallet portion (rupees). Server still caps.
  final double? walletAmount;

  Map<String, dynamic> toJson() => {
    'payAmount': payAmount,
    'rewardAmount': rewardAmount,
    'creditId': creditId,
    'eligible': eligible,
    'isBrokerageEligible': isBrokerageEligible,
    if (journeyId != null) 'journey_id': journeyId,
    if (couponCode != null && couponCode!.trim().isNotEmpty)
      'couponCode': couponCode!.trim().toUpperCase(),
    if (useWallet != null) 'useWallet': useWallet,
    if (useFullWallet != null) 'useFullWallet': useFullWallet,
    if (walletAmount != null) 'walletAmount': walletAmount,
  };
}

class GiftCardProceedPricing {
  const GiftCardProceedPricing({
    required this.faceAmount,
    required this.couponDiscount,
    required this.sharePerksDiscount,
    required this.chargeAmount,
    this.walletAmount,
    this.gatewayAmount,
  });

  final double faceAmount;
  final double couponDiscount;
  final double sharePerksDiscount;

  /// Payable after SharePerks (before wallet + coupon), when provided.
  final double chargeAmount;
  final double? walletAmount;
  final double? gatewayAmount;

  factory GiftCardProceedPricing.fromJson(Map<String, dynamic> json) {
    return GiftCardProceedPricing(
      faceAmount: parseJsonDouble(json['faceAmount']) ?? 0,
      couponDiscount: parseJsonDouble(json['couponDiscount']) ?? 0,
      sharePerksDiscount: parseJsonDouble(json['sharePerksDiscount']) ?? 0,
      chargeAmount: parseJsonDouble(json['chargeAmount']) ?? 0,
      walletAmount: parseJsonDouble(json['walletAmount']),
      gatewayAmount: parseJsonDouble(json['gatewayAmount']),
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
    return GiftCardProceedCoupon(
      code: json['code']?.toString() ?? '',
      discountApplied: parseJsonDouble(json['discountApplied']) ?? 0,
      payableAfterDiscount: parseJsonDouble(json['payableAfterDiscount']) ?? 0,
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
    this.paymentMethod = 'GATEWAY',
    this.walletAmount = 0,
    this.gatewayAmount = 0,
    this.walletMaxPercent,
    this.walletCapAmount,
    this.walletEligibleAmount,
    this.walletBalance,
    this.paid,
    this.orderStatus,
    this.claimedId,
    this.sessionId,
  });

  final bool success;
  final String message;
  final String orderId;
  final String razorpayOrderId;

  /// Razorpay Checkout amount in paise (gateway charge). For `WALLET` may be 0.
  final int amountPaise;
  final String? keyId;

  /// `WALLET` | `CASHFREE` | `RAZORPAY`
  final String? gateway;
  final String? currency;
  final GiftCardProceedPricing? pricing;
  final GiftCardProceedCoupon? coupon;

  /// `GATEWAY` | `WALLET` | `HYBRID`
  final String paymentMethod;
  final double walletAmount;
  final double gatewayAmount;

  /// Server `WALLET_MAX_PAY_PERCENT` (e.g. 70).
  final double? walletMaxPercent;

  /// Cap for this payable ignoring balance.
  final double? walletCapAmount;

  /// What this user can actually spend (cap ∩ balance).
  final double? walletEligibleAmount;

  /// Wallet balance at proceed time.
  final double? walletBalance;

  final bool? paid;
  final String? orderStatus;
  final String? claimedId;

  /// Cashfree payment session id when [gateway] is `CASHFREE`.
  final String? sessionId;

  bool get isWalletOnly {
    final g = (gateway ?? '').toUpperCase();
    final m = paymentMethod.toUpperCase();
    if (g == 'WALLET' || m == 'WALLET') return true;
    if (paid == true && gatewayAmount <= 0 && walletAmount > 0) return true;
    final status = (orderStatus ?? '').toUpperCase();
    return paid == true && status == 'PAID' && razorpayOrderId.isEmpty;
  }

  bool get isHybrid => paymentMethod.toUpperCase() == 'HYBRID';

  /// Rupees charged on the gateway (authoritative when present).
  double get gatewayChargeRupees {
    if (gatewayAmount > 0) return gatewayAmount;
    if (amountPaise > 0) return amountPaise / 100.0;
    return 0;
  }

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

    final paymentMethod =
        (data['paymentMethod'] ?? data['payment_method'])?.toString() ??
        'GATEWAY';
    final walletAmount =
        parseJsonDouble(data['walletAmount'] ?? data['wallet_amount']) ?? 0;
    final gatewayAmount =
        parseJsonDouble(data['gatewayAmount'] ?? data['gateway_amount']) ?? 0;

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
      paymentMethod: paymentMethod,
      walletAmount: walletAmount,
      gatewayAmount: gatewayAmount,
      walletMaxPercent: parseJsonDouble(
        data['walletMaxPercent'] ?? data['wallet_max_percent'],
      ),
      walletCapAmount: parseJsonDouble(
        data['walletCapAmount'] ?? data['wallet_cap_amount'],
      ),
      walletEligibleAmount: parseJsonDouble(
        data['walletEligibleAmount'] ?? data['wallet_eligible_amount'],
      ),
      walletBalance: parseJsonDouble(
        data['walletBalance'] ?? data['wallet_balance'],
      ),
      paid: data['paid'] as bool?,
      orderStatus: (data['orderStatus'] ?? data['order_status'])?.toString(),
      claimedId: (data['claimedId'] ?? data['claimed_id'])?.toString(),
      sessionId:
          (data['sessionId'] ??
                  data['paymentSessionId'] ??
                  data['payment_session_id'])
              ?.toString(),
    );
  }
}
