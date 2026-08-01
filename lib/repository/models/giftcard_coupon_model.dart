import 'package:shareperks/repository/models/home_common_models.dart';

/// Request for `POST /rewards/giftcard/coupon/apply`.
///
/// Prefer the quote form (`creditId` + `rewardAmount`) so the server computes
/// face → SharePerks → wallet → coupon. Legacy `{ code, orderAmount }` still
/// validates against [orderAmount] as-is.
class GiftCardCouponApplyRequest {
  const GiftCardCouponApplyRequest({
    required this.code,
    this.orderAmount,
    this.creditId,
    this.rewardAmount,
    this.useWallet,
    this.useFullWallet,
    this.walletAmount,
  });

  final String code;

  /// Legacy: validate coupon against this amount as-is.
  final double? orderAmount;

  /// Gift-card / credit id — enables server-side SharePerks + wallet quote.
  final String? creditId;

  /// Face / entered gift-card amount (rupees).
  final double? rewardAmount;

  final bool? useWallet;
  final bool? useFullWallet;
  final double? walletAmount;

  Map<String, dynamic> toJson() => {
    'code': code.trim().toUpperCase(),
    if (orderAmount != null) 'orderAmount': orderAmount,
    if (creditId != null && creditId!.isNotEmpty) 'creditId': creditId,
    if (rewardAmount != null) 'rewardAmount': rewardAmount,
    if (useWallet != null) 'useWallet': useWallet,
    if (useFullWallet != null) 'useFullWallet': useFullWallet,
    if (walletAmount != null) 'walletAmount': walletAmount,
  };
}

/// Wallet tender slice returned by the coupon quote.
class GiftCardCouponWalletQuote {
  const GiftCardCouponWalletQuote({
    this.balance,
    this.maxPayPercent,
    this.capAmount,
    this.eligibleAmount,
    this.appliedAmount,
  });

  final double? balance;
  final double? maxPayPercent;
  final double? capAmount;
  final double? eligibleAmount;

  /// Wallet portion applied in this quote.
  final double? appliedAmount;

  factory GiftCardCouponWalletQuote.fromJson(Map<String, dynamic> json) {
    return GiftCardCouponWalletQuote(
      balance: parseJsonDouble(json['balance']),
      maxPayPercent: parseJsonDouble(
        json['maxPayPercent'] ?? json['max_pay_percent'],
      ),
      capAmount: parseJsonDouble(json['capAmount'] ?? json['cap_amount']),
      eligibleAmount: parseJsonDouble(
        json['eligibleAmount'] ?? json['eligible_amount'],
      ),
      appliedAmount: parseJsonDouble(
        json['appliedAmount'] ??
            json['applied_amount'] ??
            json['walletAmount'] ??
            json['applied'],
      ),
    );
  }
}

/// `data` from a successful coupon apply / quote response.
class GiftCardCouponApplyData {
  const GiftCardCouponApplyData({
    required this.code,
    required this.discountType,
    this.discountAmount,
    this.discountPercentage,
    required this.discountApplied,
    required this.payableAfterDiscount,
    this.sharePerksDiscount,
    this.amountAfterSharePerks,
    this.wallet,
    this.couponBaseAmount,
    this.couponDiscount,
    this.gatewayAmount,
    this.totalPayable,
    this.paymentMethod,
  });

  final String code;

  /// `FIXED` or `PERCENTAGE`.
  final String discountType;
  final double? discountAmount;
  final double? discountPercentage;

  /// Actual ₹ coupon discount applied.
  final double discountApplied;

  /// Legacy final charge field; prefer [gatewayAmount] / [totalPayable].
  final double payableAfterDiscount;

  final double? sharePerksDiscount;
  final double? amountAfterSharePerks;
  final GiftCardCouponWalletQuote? wallet;

  /// Base used for min/max order and % discount (after SP + wallet).
  final double? couponBaseAmount;

  /// Same as [discountApplied] when the quote path is used.
  final double? couponDiscount;
  final double? gatewayAmount;

  /// Wallet applied + gateway (total user outlay).
  final double? totalPayable;

  /// `GATEWAY` | `WALLET` | `HYBRID`
  final String? paymentMethod;

  factory GiftCardCouponApplyData.fromJson(Map<String, dynamic> json) {
    final discountApplied =
        parseJsonDouble(json['discountApplied'] ?? json['couponDiscount']) ?? 0;
    final gatewayAmount = parseJsonDouble(json['gatewayAmount']);
    final payableAfterDiscount =
        parseJsonDouble(json['payableAfterDiscount']) ?? gatewayAmount ?? 0;

    GiftCardCouponWalletQuote? wallet;
    if (json['wallet'] is Map) {
      wallet = GiftCardCouponWalletQuote.fromJson(
        Map<String, dynamic>.from(json['wallet'] as Map),
      );
    }

    return GiftCardCouponApplyData(
      code: (json['code'] ?? '').toString(),
      discountType: (json['discountType'] ?? '').toString(),
      discountAmount: parseJsonDouble(json['discountAmount']),
      discountPercentage: parseJsonDouble(json['discountPercentage']),
      discountApplied: discountApplied,
      payableAfterDiscount: payableAfterDiscount,
      sharePerksDiscount: parseJsonDouble(json['sharePerksDiscount']),
      amountAfterSharePerks: parseJsonDouble(json['amountAfterSharePerks']),
      wallet: wallet,
      couponBaseAmount: parseJsonDouble(json['couponBaseAmount']),
      couponDiscount:
          parseJsonDouble(json['couponDiscount']) ?? discountApplied,
      gatewayAmount: gatewayAmount,
      totalPayable: parseJsonDouble(json['totalPayable']),
      paymentMethod: json['paymentMethod']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountType': discountType,
    'discountAmount': discountAmount,
    'discountPercentage': discountPercentage,
    'discountApplied': discountApplied,
    'payableAfterDiscount': payableAfterDiscount,
    if (sharePerksDiscount != null) 'sharePerksDiscount': sharePerksDiscount,
    if (amountAfterSharePerks != null)
      'amountAfterSharePerks': amountAfterSharePerks,
    if (couponBaseAmount != null) 'couponBaseAmount': couponBaseAmount,
    if (couponDiscount != null) 'couponDiscount': couponDiscount,
    if (gatewayAmount != null) 'gatewayAmount': gatewayAmount,
    if (totalPayable != null) 'totalPayable': totalPayable,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
  };

  bool get isFixed => discountType.toUpperCase() == 'FIXED';

  double get effectiveCouponDiscount => couponDiscount ?? discountApplied;

  double? get effectiveWalletApplied => wallet?.appliedAmount;

  String get formattedDiscountApplied =>
      '₹ ${discountApplied.toStringAsFixed(discountApplied % 1 == 0 ? 0 : 2)}';

  String get formattedPayable {
    final pay = gatewayAmount ?? payableAfterDiscount;
    return '₹ ${pay.toStringAsFixed(pay % 1 == 0 ? 0 : 2)}';
  }

  /// Whether the response includes the shared checkout quote fields.
  bool get hasQuote =>
      amountAfterSharePerks != null ||
      gatewayAmount != null ||
      totalPayable != null;
}

/// Envelope for `POST /rewards/giftcard/coupon/apply`.
class GiftCardCouponApplyResponse {
  const GiftCardCouponApplyResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final GiftCardCouponApplyData? data;

  factory GiftCardCouponApplyResponse.fromJson(Map<String, dynamic> json) {
    return GiftCardCouponApplyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? GiftCardCouponApplyData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
