import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/cashfree_order_model.dart';
import 'package:shareperks/repository/network.dart';

/// Server-side Cashfree order APIs (secret keys stay on backend).
class CashfreePaymentService {
  static final Dio _dio = createDio(Host.listingUrl);

  /// `POST /payments/cashfree/order` — returns `order_id` + `payment_session_id`.
  static Future<CashfreeCreateOrderResponse> createOrder(
    CashfreeCreateOrderRequest payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payments/cashfree/order',
      data: payload.toJson(),
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Cashfree create order: empty response');
    }
    return CashfreeCreateOrderResponse.fromJson(body);
  }

  /// `GET /payments/cashfree/order/:orderId` — verify status after SDK callback.
  static Future<Map<String, dynamic>> fetchOrderStatus(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/payments/cashfree/order/$orderId',
    );
    return response.data ?? {};
  }
}
