import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:shareperks/constants/cashfree_config.dart';
import 'package:shareperks/constants/cashfree_theme.dart';
import 'package:shareperks/repository/models/cashfree_order_model.dart';
import 'package:shareperks/repository/services/payment/cashfree.service.dart';

typedef CashfreeOnSuccess = void Function(String orderId);
typedef CashfreeOnError = void Function(CFErrorResponse error, String orderId);

/// Cashfree PG web checkout (iOS + Android).
///
/// 1. Backend creates order → `order_id` + `payment_session_id`
/// 2. [startWebCheckout] opens Cashfree checkout
/// 3. Backend verifies order via [CashfreePaymentService.fetchOrderStatus]
class CashfreePayment {
  CashfreePayment._();

  static final CFPaymentGatewayService _gateway = CFPaymentGatewayService();

  static CashfreeOnSuccess? _onSuccess;
  static CashfreeOnError? _onError;

  /// Register SDK callbacks once at app start ([main]).
  static void init() {
    _gateway.setCallback(_handleVerify, _handleError);
  }

  static void _handleVerify(String orderId) {
    _restoreSystemUi();
    _onSuccess?.call(orderId);
    _clearHandlers();
  }

  static void _handleError(CFErrorResponse errorResponse, String orderId) {
    _restoreSystemUi();
    _onError?.call(errorResponse, orderId);
    _clearHandlers();
  }

  static void _clearHandlers() {
    _onSuccess = null;
    _onError = null;
  }

  static void _applyCheckoutSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(SharePerksCashfreeTheme.statusBarOverlay);
  }

  /// Reset after checkout closes (light scaffold behind status bar).
  static void _restoreSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  /// Opens Cashfree web checkout for an existing server-created order.
  static Future<void> startWebCheckout({
    required String orderId,
    required String paymentSessionId,
    CFEnvironment? environment,
    CashfreeOnSuccess? onSuccess,
    CashfreeOnError? onError,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;

    try {
      final session = CFSessionBuilder()
          .setEnvironment(environment ?? CashfreeConfig.environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      final checkout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(SharePerksCashfreeTheme.checkout)
          .build();

      _applyCheckoutSystemUi();
      _gateway.doPayment(checkout);
    } on CFException catch (e) {
      _restoreSystemUi();
      _onError?.call(
        CFErrorResponse('FAILED', e.message, 'sdk_error', 'sdk_error'),
        orderId,
      );
      _clearHandlers();
      rethrow;
    }
  }

  /// Creates order on backend, then launches web checkout.
  static Future<void> payForReward({
    required String rewardId,
    required double amountInInr,
    required bool isShareholderEligible,
    CFEnvironment? environment,
    CashfreeOnSuccess? onSuccess,
    CashfreeOnError? onError,
  }) async {
    final order = await CashfreePaymentService.createOrder(
      CashfreeCreateOrderRequest(
        rewardId: rewardId,
        amount: amountInInr,
        isShareholderEligible: isShareholderEligible,
      ),
    );

    await startWebCheckout(
      orderId: order.orderId,
      paymentSessionId: order.paymentSessionId,
      environment: environment,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
