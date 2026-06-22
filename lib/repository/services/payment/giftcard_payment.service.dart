import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/api_error_model.dart';
import 'package:shareperks/repository/models/gift_card_proceed_model.dart';
import 'package:shareperks/repository/network.dart';

/// Gift card checkout — create Cashfree session via listing API.
class GiftCardPaymentService {
  GiftCardPaymentService._();

  static final Dio _dio = createDio(Host.listingUrl);

  /// `POST /payment/giftcard/proceed` — returns Cashfree `sessionId` + `orderId`.
  ///
  /// Throws [ApiErrorResponse] on `4xx`/`5xx` with a JSON error body.
  static Future<GiftCardProceedResponse> proceedGiftCardPayment(
    GiftCardProceedRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payment/giftcard/proceed',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const FormatException('Gift card proceed: empty response body');
      }

      final result = GiftCardProceedResponse.fromJson(data);
      if (!result.success ||
          result.sessionId.isEmpty ||
          result.orderId.isEmpty) {
        throw ApiErrorResponse(
          success: false,
          message: result.message.isNotEmpty
              ? result.message
              : 'Could not create payment session',
        );
      }
      return result;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        throw ApiErrorResponse.fromJson(body);
      }
      rethrow;
    }
  }
}
