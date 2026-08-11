/// Google Analytics / Google Ads conversion events emitted by the app.
///
/// Mark these as **Key events / Conversions** in GA4 Admin, then import into
/// Google Ads (Tools → Measurement → Conversions → Firebase/GA4).
class GoogleConversions {
  GoogleConversions._();

  /// GA4 recommended / custom events used for Ads bidding & reporting.
  static const Map<String, String> events = {
    'first_open': 'Install (Firebase auto)',
    'sp_first_open': 'First open (SharePerks explicit)',
    'install_attributed': 'Play Install Referrer captured',
    'sign_up': 'Registration / signup completed',
    'login': 'Login (returning user OTP verified)',
    'purchase': 'Gift card payment succeeded',
    'campaign_details': 'UTM / Google Ads campaign params',
    'deeplink_opened': 'Deep link open with optional UTM',
  };

  /// Event names that should be marked as conversions in GA4 → Google Ads.
  static const conversionEventNames = [
    'first_open',
    'sp_first_open',
    'sign_up',
    'login',
    'purchase',
  ];
}
