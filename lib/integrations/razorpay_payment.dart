import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shareperks/constants/razorpay_config.dart';

typedef RazorpayOnSuccess = void Function(PaymentSuccessResponse response);
typedef RazorpayOnError = void Function(PaymentFailureResponse response);
typedef RazorpayOnExternalWallet =
    void Function(ExternalWalletResponse response);

/// Razorpay Checkout wrapper (iOS + Android).
///
/// 1. Backend `POST /payment/giftcard/proceed` → order + razorpayOrderId
/// 2. [openCheckout] opens Razorpay Checkout
/// 3. Backend confirms via `POST /payments/razorpay/verify`
class RazorpayPayment {
  RazorpayPayment._();

  static Razorpay? _razorpay;
  static RazorpayOnSuccess? _onSuccess;
  static RazorpayOnError? _onError;
  static RazorpayOnExternalWallet? _onExternalWallet;

  static bool isCheckoutCancelled(PaymentFailureResponse error) {
    if (error.code == Razorpay.PAYMENT_CANCELLED) return true;
    final message = (error.message ?? '').toLowerCase().trim();
    // Razorpay often returns a bare "payment" / "payment cancelled" when the
    // user closes Checkout without completing.
    if (message.isEmpty || message == 'payment') return true;
    return message.contains('cancel') ||
        message.contains('cancelled') ||
        message.contains('dismiss') ||
        message.contains('closed by user') ||
        message.contains('user closed');
  }

  /// Register SDK callbacks once at app start ([main]).
  static void init() {
    _razorpay ??= Razorpay();
    _razorpay!
      ..clear()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static void _handleSuccess(PaymentSuccessResponse response) {
    final cb = _onSuccess;
    _clearHandlers();
    cb?.call(response);
  }

  static void _handleError(PaymentFailureResponse response) {
    final cb = _onError;
    _clearHandlers();
    cb?.call(response);
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  static void _clearHandlers() {
    _onSuccess = null;
    _onError = null;
    _onExternalWallet = null;
  }

  /// Clears plugin listeners (call on teardown if needed).
  static void clear() {
    _clearHandlers();
    _razorpay?.clear();
  }

  /// Opens Razorpay Checkout for a server-created order.
  static void openCheckout({
    required String razorpayOrderId,
    required int amountPaise,
    String? keyId,
    String name = 'SharePerks',
    String? description,
    String currency = 'INR',
    Map<String, dynamic>? prefill,
    RazorpayOnSuccess? onSuccess,
    RazorpayOnError? onError,
    RazorpayOnExternalWallet? onExternalWallet,
  }) {
    init();
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    final key = (keyId != null && keyId.isNotEmpty)
        ? keyId
        : RazorpayConfig.keyId;

    final options = <String, dynamic>{
      'key': key,
      'amount': amountPaise,
      'currency': currency,
      'name': name,
      'order_id': razorpayOrderId,
      'theme': {'color': '#6500E0'},
      if (description != null && description.isNotEmpty)
        'description': description,
      if (prefill != null && prefill.isNotEmpty) 'prefill': prefill,
    };

    _razorpay!.open(options);
  }
}
