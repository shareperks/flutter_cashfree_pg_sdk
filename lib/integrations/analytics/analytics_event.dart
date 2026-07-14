/// Event categories. MUST stay in sync with the server's
/// `eventCategoryEnum` in `data_service/src/services/tracking/tracking.schema.ts`.
class EventCategory {
  EventCategory._();

  static const lifecycle = 'lifecycle';
  static const screen = 'screen';
  static const auth = 'auth';
  static const discovery = 'discovery';
  static const funnelGiftcard = 'funnel:giftcard';
  static const funnelCashback = 'funnel:cashback';
  static const funnelPromocode = 'funnel:promocode';
  static const funnelDemat = 'funnel:demat';
  static const funnelWallet = 'funnel:wallet';
  static const funnelReferral = 'funnel:referral';
  static const engagement = 'engagement';
  static const error = 'error';
  static const revenue = 'revenue';
  static const custom = 'custom';
}

/// All analytics events the app may emit. Adding a new event MUST be a
/// 3-step process:
///   1. Add a constructor here (one place to find/audit every event).
///   2. Call `AnalyticsService.instance.track(AnalyticsEvent.xyz, {...})`
///      at the trigger point. NEVER pass a string literal.
///   3. Update `docs/flutter/integrations/analytics/README.md`.
///
/// The [requiresConsent] flag follows the rule from the architecture doc:
/// crash reports, payment receipts, and security events are unflagged so
/// they fire even before the user accepts the analytics consent sheet.
class AnalyticsEvent {
  /// Event name in `lower_snake_case` (matches server validator
  /// `/^[a-z][a-z0-9_]*$/`, max 80 chars).
  final String name;

  /// Category. One of [EventCategory].
  final String category;

  /// If true, the event is dropped until `ConsentManager.isGranted()` is true.
  final bool requiresConsent;

  const AnalyticsEvent._(this.name, this.category, {this.requiresConsent = true});

  // ——— App lifecycle ———
  static const appOpened = AnalyticsEvent._('app_opened', EventCategory.lifecycle, requiresConsent: false);
  static const appForegrounded = AnalyticsEvent._('app_foregrounded', EventCategory.lifecycle, requiresConsent: false);
  static const appBackgrounded = AnalyticsEvent._('app_backgrounded', EventCategory.lifecycle, requiresConsent: false);
  static const screenView = AnalyticsEvent._('screen_view', EventCategory.screen);
  static const screenSession = AnalyticsEvent._('screen_session', EventCategory.screen);
  static const screenExit = AnalyticsEvent._('screen_exit', EventCategory.screen);
  static const deeplinkOpened = AnalyticsEvent._('deeplink_opened', EventCategory.lifecycle);
  static const forceUpdateShown = AnalyticsEvent._('force_update_shown', EventCategory.lifecycle, requiresConsent: false);
  static const connectivityLost = AnalyticsEvent._('connectivity_lost', EventCategory.lifecycle, requiresConsent: false);

  // ——— Auth funnel ———
  static const landingViewed = AnalyticsEvent._('landing_viewed', EventCategory.auth);
  static const loginStarted = AnalyticsEvent._('login_started', EventCategory.auth);
  static const otpSent = AnalyticsEvent._('otp_sent', EventCategory.auth);
  static const otpResent = AnalyticsEvent._('otp_resent', EventCategory.auth);
  static const otpVerified = AnalyticsEvent._('otp_verified', EventCategory.auth);
  static const otpFailed = AnalyticsEvent._('otp_failed', EventCategory.auth);
  static const profileSetupStarted = AnalyticsEvent._('profile_setup_started', EventCategory.auth);
  static const profileCompleted = AnalyticsEvent._('profile_completed', EventCategory.auth);
  static const signupCompleted = AnalyticsEvent._('signup_completed', EventCategory.auth);
  static const logout = AnalyticsEvent._('logout', EventCategory.auth, requiresConsent: false);

  // ——— Discovery ———
  static const homeLoaded = AnalyticsEvent._('home_loaded', EventCategory.discovery);
  static const categoryViewed = AnalyticsEvent._('category_viewed', EventCategory.discovery);
  static const brandViewed = AnalyticsEvent._('brand_viewed', EventCategory.discovery);
  static const companyViewed = AnalyticsEvent._('company_viewed', EventCategory.discovery);
  static const topPerksViewed = AnalyticsEvent._('top_perks_viewed', EventCategory.discovery);
  static const topBrandsViewed = AnalyticsEvent._('top_brands_viewed', EventCategory.discovery);
  static const perkTypeViewed = AnalyticsEvent._('perk_type_viewed', EventCategory.discovery);
  static const unlockedPerksViewed = AnalyticsEvent._('unlocked_perks_viewed', EventCategory.discovery);
  static const perkCardClicked = AnalyticsEvent._('perk_card_clicked', EventCategory.discovery);
  static const perkEligibilityChecked = AnalyticsEvent._('perk_eligibility_checked', EventCategory.discovery);
  static const requestPerkSubmitted = AnalyticsEvent._('request_perk_submitted', EventCategory.discovery);
  static const votingBrandSelected = AnalyticsEvent._('voting_brand_selected', EventCategory.discovery);

  // ——— Giftcard funnel (revenue path) ———
  static const giftcardPerkViewed = AnalyticsEvent._('giftcard_perk_viewed', EventCategory.funnelGiftcard);
  static const giftcardEligibilityChecked = AnalyticsEvent._('giftcard_eligibility_checked', EventCategory.funnelGiftcard);
  static const giftcardAmountScreenViewed = AnalyticsEvent._('giftcard_amount_screen_viewed', EventCategory.funnelGiftcard);
  static const giftcardAmountSelected = AnalyticsEvent._('giftcard_amount_selected', EventCategory.funnelGiftcard);
  static const giftcardPaymentInitiated = AnalyticsEvent._('giftcard_payment_initiated', EventCategory.funnelGiftcard, requiresConsent: false);
  static const giftcardPaymentOrderCreated = AnalyticsEvent._('giftcard_payment_order_created', EventCategory.funnelGiftcard, requiresConsent: false);
  static const giftcardCheckoutOpened = AnalyticsEvent._('giftcard_checkout_opened', EventCategory.funnelGiftcard, requiresConsent: false);
  static const giftcardPaymentSucceeded = AnalyticsEvent._('giftcard_payment_succeeded', EventCategory.revenue, requiresConsent: false);
  static const giftcardPaymentFailed = AnalyticsEvent._('giftcard_payment_failed', EventCategory.funnelGiftcard, requiresConsent: false);
  static const giftcardPaymentCancelled = AnalyticsEvent._('giftcard_payment_cancelled', EventCategory.funnelGiftcard, requiresConsent: false);
  static const giftcardPaymentRetried = AnalyticsEvent._('giftcard_payment_retried', EventCategory.funnelGiftcard);
  static const giftcardRedeemedCodeViewed = AnalyticsEvent._('giftcard_redeemed_code_viewed', EventCategory.funnelGiftcard);
  static const giftcardCodeCopied = AnalyticsEvent._('giftcard_code_copied', EventCategory.funnelGiftcard);
  static const giftcardPaymentAbandoned = AnalyticsEvent._('giftcard_payment_abandoned', EventCategory.funnelGiftcard);

  // ——— Cashback funnel ———
  static const cashbackPerkViewed = AnalyticsEvent._('cashback_perk_viewed', EventCategory.funnelCashback);
  static const cashbackEligibilityChecked = AnalyticsEvent._('cashback_eligibility_checked', EventCategory.funnelCashback);
  static const cashbackTermsRead = AnalyticsEvent._('cashback_terms_read', EventCategory.funnelCashback);
  static const cashbackClaimStarted = AnalyticsEvent._('cashback_claim_started', EventCategory.funnelCashback);
  static const cashbackClaimCompleted = AnalyticsEvent._('cashback_claim_completed', EventCategory.revenue);

  // ——— Promocode funnel ———
  static const promocodePerkViewed = AnalyticsEvent._('promocode_perk_viewed', EventCategory.funnelPromocode);
  static const promocodeEligibilityChecked = AnalyticsEvent._('promocode_eligibility_checked', EventCategory.funnelPromocode);
  static const promocodeRevealed = AnalyticsEvent._('promocode_revealed', EventCategory.funnelPromocode);
  static const promocodeRevealBlocked = AnalyticsEvent._('promocode_reveal_blocked', EventCategory.funnelPromocode);
  static const promocodeCopied = AnalyticsEvent._('promocode_copied', EventCategory.funnelPromocode);

  // ——— Demat / holding funnel ———
  static const linkDematStarted = AnalyticsEvent._('link_demat_started', EventCategory.funnelDemat);
  static const brokerListViewed = AnalyticsEvent._('broker_list_viewed', EventCategory.funnelDemat);
  static const brokerSelected = AnalyticsEvent._('broker_selected', EventCategory.funnelDemat);
  static const smallcaseGatewayOpened = AnalyticsEvent._('smallcase_gateway_opened', EventCategory.funnelDemat);
  static const smallcaseGatewaySuccess = AnalyticsEvent._('smallcase_gateway_success', EventCategory.funnelDemat);
  static const smallcaseGatewayFailed = AnalyticsEvent._('smallcase_gateway_failed', EventCategory.funnelDemat);
  static const holdingStatementUploaded = AnalyticsEvent._('holding_statement_uploaded', EventCategory.funnelDemat);
  static const holdingsSynced = AnalyticsEvent._('holdings_synced', EventCategory.funnelDemat);

  // ——— Wallet & payout funnel ———
  static const walletViewed = AnalyticsEvent._('wallet_viewed', EventCategory.funnelWallet);
  static const earningViewed = AnalyticsEvent._('earning_viewed', EventCategory.funnelWallet);
  static const walletHistoryViewed = AnalyticsEvent._('wallet_history_viewed', EventCategory.funnelWallet);
  static const payoutStarted = AnalyticsEvent._('payout_started', EventCategory.funnelWallet);
  static const payoutRequestSubmitted = AnalyticsEvent._('payout_request_submitted', EventCategory.funnelWallet, requiresConsent: false);
  static const payoutSucceeded = AnalyticsEvent._('payout_succeeded', EventCategory.revenue, requiresConsent: false);
  static const payoutFailed = AnalyticsEvent._('payout_failed', EventCategory.funnelWallet, requiresConsent: false);

  // ——— Referral funnel ———
  static const referScreenViewed = AnalyticsEvent._('refer_screen_viewed', EventCategory.funnelReferral);
  static const referCodeCopied = AnalyticsEvent._('refer_code_copied', EventCategory.funnelReferral);
  static const referShareIntent = AnalyticsEvent._('refer_share_intent', EventCategory.funnelReferral);

  // ——— Notifications & engagement ———
  static const pushTokenRegistered = AnalyticsEvent._('push_token_registered', EventCategory.engagement, requiresConsent: false);
  static const pushReceived = AnalyticsEvent._('push_received', EventCategory.engagement);
  static const pushOpened = AnalyticsEvent._('push_opened', EventCategory.engagement);
  static const notificationScreenViewed = AnalyticsEvent._('notification_screen_viewed', EventCategory.engagement);
  static const buttonClicked = AnalyticsEvent._('button_clicked', EventCategory.engagement);
  static const inappMessageShown = AnalyticsEvent._('inapp_message_shown', EventCategory.engagement);
  static const inappMessageClicked = AnalyticsEvent._('inapp_message_clicked', EventCategory.engagement);

  // ——— Errors & diagnostics ———
  static const apiCall = AnalyticsEvent._('api_call', EventCategory.error, requiresConsent: false);
  static const apiError = AnalyticsEvent._('api_error', EventCategory.error, requiresConsent: false);
  static const appError = AnalyticsEvent._('app_error', EventCategory.error, requiresConsent: false);
  static const networkTimeout = AnalyticsEvent._('network_timeout', EventCategory.error, requiresConsent: false);
  static const routeBlocked = AnalyticsEvent._('route_blocked', EventCategory.lifecycle, requiresConsent: false);

  /// Escape hatch for ad-hoc events. Prefer a typed constant above; only use
  /// this from the legacy `UserActivityTrackingService` compat shim or
  /// short-lived experiments.
  ///
  /// [name] must match `/^[a-z][a-z0-9_]*$/` and be <= 80 chars.
  factory AnalyticsEvent.custom(
    String name, {
    String category = EventCategory.custom,
    bool requiresConsent = true,
  }) {
    assert(RegExp(r'^[a-z][a-z0-9_]{0,79}$').hasMatch(name),
        'AnalyticsEvent.custom name must be lower_snake_case (<=80 chars)');
    return AnalyticsEvent._(name, category, requiresConsent: requiresConsent);
  }
}
