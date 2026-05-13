/// Body for `POST /payout/request`.
class PayoutRequestPayload {
  PayoutRequestPayload({required this.amount, required this.upi});

  final num amount;
  final String upi;

  Map<String, dynamic> toJson() => {'amount': amount, 'upi': upi.trim()};
}

/// Parsed envelope from payout request API (fields vary by backend).
class PayoutRequestResponse {
  PayoutRequestResponse({this.success, this.message, this.data, this.raw});

  final bool? success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? raw;

  factory PayoutRequestResponse.fromJson(Map<String, dynamic> json) {
    return PayoutRequestResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'],
      raw: json,
    );
  }
}
