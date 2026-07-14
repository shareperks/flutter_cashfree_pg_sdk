import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/api_error_model.dart';
import 'package:shareperks/repository/models/razorpay_verify_model.dart';
import 'package:shareperks/repository/network.dart';

/// Server-side Razorpay verify + gift-card order status.
class RazorpayPaymentService {
  RazorpayPaymentService._();

  static final Dio _dio = createDio(Host.listingUrl);

  /// `POST /payments/razorpay/verify` — HMAC verify + mark PAID.
  static Future<RazorpayVerifyResponse> verifyPayment(
    RazorpayVerifyRequest payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payments/razorpay/verify',
        data: payload.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw StateError('Razorpay verify: empty response');
      }
      return RazorpayVerifyResponse.fromJson(body);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        throw ApiErrorResponse.fromJson(body);
      }
      rethrow;
    }
  }

  /// `GET /payment/giftcard/order/:orderId` — recovery after verify fail.
  static Future<Map<String, dynamic>> fetchGiftCardOrderStatus(
    String orderId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payment/giftcard/order/$orderId',
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{
        'success': false,
        'message': e.message ?? 'Could not fetch payment status',
        'httpStatus': e.response?.statusCode,
      };
    }
  }
}
