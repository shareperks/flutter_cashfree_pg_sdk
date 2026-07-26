import 'package:shareperks/repository/models/home_common_models.dart';

/// Request for `POST /rewards/giftcard/coupon/apply`.
class GiftCardCouponApplyRequest {
  const GiftCardCouponApplyRequest({
    required this.code,
    required this.orderAmount,
  });

  final String code;

  /// Face / entered gift-card amount used for coupon eligibility.
  /// Do not send a SharePerks- or wallet-reduced base.
  final double orderAmount;

  Map<String, dynamic> toJson() => {
    'code': code.trim().toUpperCase(),
    'orderAmount': orderAmount,
  };
}

/// `data` from a successful coupon apply response.
class GiftCardCouponApplyData {
  const GiftCardCouponApplyData({
    required this.code,
    required this.discountType,
    this.discountAmount,
    this.discountPercentage,
    required this.discountApplied,
    required this.payableAfterDiscount,
  });

  final String code;

  /// `FIXED` or `PERCENTAGE`.
  final String discountType;
  final double? discountAmount;
  final double? discountPercentage;

  /// Actual ₹ discount applied to this order.
  final double discountApplied;

  /// Final amount to charge after coupon.
  final double payableAfterDiscount;

  factory GiftCardCouponApplyData.fromJson(Map<String, dynamic> json) {
    return GiftCardCouponApplyData(
      code: (json['code'] ?? '').toString(),
      discountType: (json['discountType'] ?? '').toString(),
      discountAmount: parseJsonDouble(json['discountAmount']),
      discountPercentage: parseJsonDouble(json['discountPercentage']),
      discountApplied: parseJsonDouble(json['discountApplied']) ?? 0,
      payableAfterDiscount: parseJsonDouble(json['payableAfterDiscount']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountType': discountType,
    'discountAmount': discountAmount,
    'discountPercentage': discountPercentage,
    'discountApplied': discountApplied,
    'payableAfterDiscount': payableAfterDiscount,
  };

  bool get isFixed => discountType.toUpperCase() == 'FIXED';

  String get formattedDiscountApplied =>
      '₹ ${discountApplied.toStringAsFixed(discountApplied % 1 == 0 ? 0 : 2)}';

  String get formattedPayable =>
      '₹ ${payableAfterDiscount.toStringAsFixed(payableAfterDiscount % 1 == 0 ? 0 : 2)}';
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
