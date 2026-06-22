/// Body for `POST /payment/giftcard/proceed`.
class GiftCardProceedRequest {
  const GiftCardProceedRequest({
    required this.payAmount,
    required this.rewardAmount,
    required this.creditId,
    required this.eligible,
  });

  final double payAmount;
  final double rewardAmount;
  final String creditId;
  final bool eligible;

  Map<String, dynamic> toJson() => {
    'payAmount': payAmount,
    'rewardAmount': rewardAmount,
    'creditId': creditId,
    'eligible': eligible,
  };
}

/// Direct `200` body from `POST /payment/giftcard/proceed` (no `data` wrapper).
class GiftCardProceedResponse {
  const GiftCardProceedResponse({
    required this.success,
    required this.message,
    required this.sessionId,
    required this.orderId,
  });

  final bool success;
  final String message;
  final String sessionId;
  final String orderId;

  factory GiftCardProceedResponse.fromJson(Map<String, dynamic> json) {
    return GiftCardProceedResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
    );
  }
}
