/// Razorpay Key ID for Checkout. Prefer `keyId` from proceed response.
///
/// Override locally / CI with:
/// `--dart-define=RAZORPAY_KEY_ID=rzp_live_...`
///
/// Never put the key secret in the Flutter app.
class RazorpayConfig {
  RazorpayConfig._();

  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_TDR9qcSk0ZGbWV',
  );
}
