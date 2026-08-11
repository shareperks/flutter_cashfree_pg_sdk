# Analytics — Flutter integration

`lib/integrations/analytics/` — single-facade analytics layer for the
SharePerks Flutter app. Screens call **only** `AnalyticsService.instance`;
swapping or adding vendors (Firebase, AppsFlyer, CleverTap, ...) is a one-file
change in `analytics_service.dart`.

## Folder layout

```
lib/integrations/analytics/
├── analytics_service.dart       Public facade. Init in main, call from anywhere.
├── analytics_event.dart         Typed registry of every event. No string literals in screens.
├── analytics_context.dart       Auto-captured app_version / platform / locale / network.
├── anon_id.dart                 First-launch UUID kept in SharedPreferences.
├── session_id.dart              One id per cold start.
├── consent_manager.dart         granted / denied / unknown flag.
├── route_observer.dart          AnalyticsRouteObserver — drop-in for routeObserver.
├── campaign_attribution.dart    UTM / gclid last-touch store (Google Ads).
├── install_attribution.dart     Play Install Referrer (Android deferred).
├── deep_link_tracker.dart       app_links → deeplink_opened + UTM.
├── google_conversions.dart      GA4 / Google Ads conversion event list.
├── sinks/
│   ├── analytics_sink.dart      Sink interface.
│   ├── debug_sink.dart          kDebugMode pretty printer.
│   ├── firebase_sink.dart       Firebase Analytics (GA4) + Consent Mode.
│   ├── meta_sink.dart           Meta App Events (Facebook SDK).
│   └── server_sink.dart         POSTs to https://listing.shareperks.in/track/batch
│                                with offline queue + retry + backoff.
└── README.md                    This file.
```

## How to add a new event

1. Add a `static const` in `analytics_event.dart`.
2. Call it at the trigger point:
   ```dart
   AnalyticsService.instance.track(
     AnalyticsEvent.giftcardAmountSelected,
     {'amount': amount, 'denomination_type': 'fixed'},
   );
   ```
3. Append it to the table below.

> Names MUST match `^[a-z][a-z0-9_]*$`, max 80 chars (server validator).
> Props are free-form JSON; keep keys `lower_snake_case`.

## Event taxonomy (v1)

### App lifecycle

| Event | When | Key props |
|-------|------|-----------|
| `app_opened` | First frame of cold start (in `AnalyticsService.init`) | `is_first_open`, `from_deeplink`, `source` |
| `app_foregrounded` | `AppLifecycleState.resumed` | `paused_for_ms` |
| `app_backgrounded` | `AppLifecycleState.paused` | — |
| `screen_view` | Every `didPush` / `didReplace` / `didPopNext` (via `AnalyticsRouteObserver`) | `screen_name`, `previous_screen` |
| `deeplink_opened` | App launched / resumed via universal link | `url`, `path`, `utm_*` |
| `force_update_shown` | `NewUpdateAvailableScreen` mount | `current_version`, `min_version` |
| `connectivity_lost` | `Connectivity().onConnectivityChanged` → none | — |

### Auth funnel

| Event | When |
|-------|------|
| `landing_viewed` | `LandingScreen` mount |
| `login_started` | User taps Login / focuses mobile field |
| `otp_sent` | `AuthService.sendOtp` success |
| `otp_resent` | `AuthService.resendOtp` success |
| `otp_verified` | `AuthService.verifyOtp` returns token |
| `otp_failed` | `verifyOtp` throws / non-2xx |
| `profile_setup_started` | `SetupScreen` mount |
| `profile_completed` | `AuthService.completeProfile` success |
| `signup_completed` | First `profile_completed` for a new userId |
| `logout` | `UserDataProvider.clearSession` |

### Discovery / browse

| Event | Key props |
|-------|-----------|
| `home_loaded` | `latency_ms`, `is_error` |
| `category_viewed` | `category_id` |
| `brand_viewed` | `brand_id`, `source` (`home` / `top_brands` / `search`) |
| `company_viewed` | `company_id`, `source` |
| `top_perks_viewed` | `count` |
| `top_brands_viewed` | `count` |
| `perk_type_viewed` | `type` (`cashback` / `giftcard` / `promocode`) |
| `unlocked_perks_viewed` | `count` |
| `perk_card_clicked` | `perk_id`, `perk_type`, `brand_id`, `position`, `source` |
| `request_perk_submitted` | `brand_name`, `category` |
| `voting_brand_selected` | `brand_id` |

### Giftcard funnel (revenue)

```
giftcard_perk_viewed
  → giftcard_eligibility_checked        (eligible: true|false)
    → giftcard_amount_screen_viewed
      → giftcard_amount_selected        (amount, denomination_type)
        → giftcard_payment_initiated    (razorpay_order_id, amount)
          → giftcard_payment_succeeded  ✓ revenue
          → giftcard_payment_failed     ✗ reason, error_code
            → giftcard_payment_retried
giftcard_redeemed_code_viewed
giftcard_code_copied
```

### Cashback funnel

`cashback_perk_viewed`, `cashback_terms_read`, `cashback_claim_started`,
`cashback_claim_completed` (revenue).

### Promocode funnel

`promocode_perk_viewed`, `promocode_revealed`, `promocode_copied`.

### Demat / holding funnel

`link_demat_started`, `broker_list_viewed`, `broker_selected`,
`smallcase_gateway_opened`, `smallcase_gateway_success`,
`smallcase_gateway_failed`, `holding_statement_uploaded`, `holdings_synced`.

### Wallet / payout funnel

`wallet_viewed`, `earning_viewed`, `wallet_history_viewed`, `payout_started`,
`payout_request_submitted`, `payout_succeeded` (revenue), `payout_failed`.

### Referral funnel

`refer_screen_viewed`, `refer_code_copied`, `refer_share_intent`
(`channel: whatsapp|sms|system`).

### Notifications & engagement

`push_token_registered`, `push_received`, `push_opened` (`campaign_id`),
`notification_screen_viewed`, `inapp_message_shown`, `inapp_message_clicked`.

### Errors & diagnostics

`api_call`, `api_error`, `app_error`, `network_timeout`, `route_blocked`.

## Consent

Events tagged `requiresConsent: true` (in `analytics_event.dart`) are dropped
until `ConsentManager.grant()` is called. Crash, payment-receipt, and security
events stay unflagged.

Toggle from settings:
```dart
await ConsentManager.grant();   // or .deny()
AnalyticsService.instance.onConsentChanged(true);
```

## Debugging

In `kDebugMode` the `DebugSink` prints every event to the Flutter console.
You can also call `GET /track/me/recent` against the data_service backend with
your JWT to see your last 50 server-stored events.
