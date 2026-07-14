/// Body for `POST /payments/razorpay/verify`.
class RazorpayVerifyRequest {
  const RazorpayVerifyRequest({
    required this.orderId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String orderId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'razorpay_order_id': razorpayOrderId,
    'razorpay_payment_id': razorpayPaymentId,
    'razorpay_signature': razorpaySignature,
  };
}

/// Response from `POST /payments/razorpay/verify`.
class RazorpayVerifyResponse {
  const RazorpayVerifyResponse({
    required this.paid,
    this.success,
    this.claimedId,
    this.orderStatus,
    this.message,
    this.raw,
  });

  final bool paid;
  final bool? success;
  final String? claimedId;
  final String? orderStatus;
  final String? message;
  final Map<String, dynamic>? raw;

  factory RazorpayVerifyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final status = (data['orderStatus'] ?? data['order_status'] ?? data['status'])
        ?.toString()
        .toUpperCase();
    final paid =
        data['paid'] == true ||
        status == 'PAID' ||
        (data['success'] == true && status == 'PAID');

    final claimed =
        data['claimedId']?.toString() ?? data['claimed_id']?.toString();

    return RazorpayVerifyResponse(
      paid: paid,
      success: data['success'] as bool? ?? json['success'] as bool?,
      claimedId: (claimed != null && claimed.isNotEmpty) ? claimed : null,
      orderStatus: status,
      message: (data['message'] ?? json['message'])?.toString(),
      raw: Map<String, dynamic>.from(data),
    );
  }
}

/// Parsed body from `GET /payment/giftcard/order/:orderId`.
class GiftCardOrderStatusData {
  GiftCardOrderStatusData._();

  static String? orderStatusOf(Map<String, dynamic>? resp) {
    if (resp == null) return null;
    final data = resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : resp;
    final raw =
        data['orderStatus'] ?? data['order_status'] ?? data['status'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value.toUpperCase();
  }

  static bool isPaid(Map<String, dynamic> resp) {
    final data = resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : resp;
    if (data['paid'] == true) return true;
    if (orderStatusOf(resp) != 'PAID') return false;
    if (resp['success'] == true || data['success'] == true) return true;
    return false;
  }

  static String? claimedIdOf(Map<String, dynamic>? resp) {
    if (resp == null) return null;
    final data = resp['data'] is Map<String, dynamic>
        ? resp['data'] as Map<String, dynamic>
        : resp;

    final fromRoot =
        data['claimedId']?.toString() ?? data['claimed_id']?.toString();
    if (fromRoot != null && fromRoot.isNotEmpty) return fromRoot;

    final creditOrder = data['creditOrder'];
    if (creditOrder is Map<String, dynamic>) {
      final fromCredit = creditOrder['claimedId']?.toString();
      if (fromCredit != null && fromCredit.isNotEmpty) return fromCredit;
    }

    return null;
  }
}
