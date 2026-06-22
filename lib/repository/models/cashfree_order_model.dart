/// Server response after `POST /payments/cashfree/order`.
class CashfreeCreateOrderResponse {
  CashfreeCreateOrderResponse({
    required this.orderId,
    required this.paymentSessionId,
    this.orderAmount,
    this.orderCurrency,
    this.raw,
  });

  final String orderId;
  final String paymentSessionId;
  final double? orderAmount;
  final String? orderCurrency;
  final Map<String, dynamic>? raw;

  factory CashfreeCreateOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final orderId = (data['order_id'] ?? data['orderId'])?.toString();
    final sessionId =
        (data['payment_session_id'] ?? data['paymentSessionId'])?.toString();

    if (orderId == null || orderId.isEmpty) {
      throw FormatException('Cashfree order: missing order_id');
    }
    if (sessionId == null || sessionId.isEmpty) {
      throw FormatException('Cashfree order: missing payment_session_id');
    }

    return CashfreeCreateOrderResponse(
      orderId: orderId,
      paymentSessionId: sessionId,
      orderAmount: _parseAmount(data['order_amount'] ?? data['orderAmount']),
      orderCurrency: data['order_currency'] as String? ??
          data['orderCurrency'] as String?,
      raw: Map<String, dynamic>.from(data),
    );
  }

  static double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Body for creating a Cashfree order on the backend.
class CashfreeCreateOrderRequest {
  CashfreeCreateOrderRequest({
    required this.rewardId,
    required this.amount,
    required this.isShareholderEligible,
    this.currency = 'INR',
  });

  final String rewardId;
  final double amount;
  final bool isShareholderEligible;
  final String currency;

  Map<String, dynamic> toJson() => {
    'rewardId': rewardId,
    'amount': amount,
    'isShareholderEligible': isShareholderEligible,
    'order_currency': currency,
  };
}
