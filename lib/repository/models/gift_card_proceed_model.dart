/// Body for `POST /payment/giftcard/proceed`.
class GiftCardProceedRequest {
  const GiftCardProceedRequest({
    required this.payAmount,
    required this.rewardAmount,
    required this.creditId,
    required this.eligible,
    this.isBrokerageEligible = false,
    this.journeyId,
  });

  final double payAmount;
  final double rewardAmount;
  final String creditId;

  /// Fully eligible (max holder rate). Mid-tier users remain `false`.
  final bool eligible;

  /// Mid tier: broker connected with holdings, not fully eligible.
  final bool isBrokerageEligible;
  final String? journeyId;

  Map<String, dynamic> toJson() => {
    'payAmount': payAmount,
    'rewardAmount': rewardAmount,
    'creditId': creditId,
    'eligible': eligible,
    'isBrokerageEligible': isBrokerageEligible,
    if (journeyId != null) 'journey_id': journeyId,
  };
}

/// Direct `200` body from `POST /payment/giftcard/proceed` (Razorpay gateway).
class GiftCardProceedResponse {
  const GiftCardProceedResponse({
    required this.success,
    required this.message,
    required this.orderId,
    required this.razorpayOrderId,
    required this.amountPaise,
    this.keyId,
  });

  final bool success;
  final String message;
  final String orderId;
  final String razorpayOrderId;
  /// Amount in paise for Razorpay Checkout.
  final int amountPaise;
  final String? keyId;

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
      message:
          (data['message'] ?? json['message'])?.toString() ?? '',
      orderId: (data['orderId'] ?? data['order_id'])?.toString() ?? '',
      razorpayOrderId:
          (data['razorpayOrderId'] ?? data['razorpay_order_id'])
              ?.toString() ??
          '',
      amountPaise: amountPaise,
      keyId: (data['keyId'] ?? data['key_id'])?.toString(),
    );
  }
}
