# SharePerks — User Tracking & Analytics Architecture

> A complete blueprint of every viable user-tracking layer we can wire into the
> SharePerks Flutter app, plus a reference implementation pattern. Use this as
> the single source of truth when picking vendors, naming events, or adding new
> tracking calls.

---

## 1. Goals of this document

1. Catalogue **every category** of tracking that is meaningful for a perks /
   rewards app like SharePerks.
2. Map each category to **recommended Flutter SDKs**, the touchpoint in our
   codebase, and what we get out of it.
3. Define a **single internal facade** (`AnalyticsService`) so screens never
   call vendor SDKs directly.
4. Lock down a **first-party event taxonomy** that is consistent across product
   analytics, marketing, CRM, and the data warehouse.
5. Cover **privacy / consent / store-policy** requirements (Android Ad ID, iOS
   ATT, India DPDP, GDPR).

---

## 2. The 9 tracking layers

A modern consumer app typically combines several of these. They are not
interchangeable — each answers a different question.

| # | Layer                          | Question it answers                                       | Recommended primary | Reasonable alternates                  |
|---|--------------------------------|------------------------------------------------------------|---------------------|----------------------------------------|
| 1 | Product analytics (events)     | What are users doing inside the app?                       | Firebase Analytics  | Mixpanel, Amplitude, PostHog, Segment  |
| 2 | Crash + error reporting        | What is breaking in production?                            | Sentry              | Firebase Crashlytics                   |
| 3 | Performance + network tracing  | Which screens / APIs are slow?                             | Sentry Performance  | Firebase Performance, Datadog RUM      |
| 4 | Attribution / install tracking | Where do paid + organic installs come from?                | AppsFlyer           | Branch, Adjust, Singular               |
| 5 | Push + lifecycle CRM           | Re-engaging users with personalised journeys               | CleverTap           | MoEngage, OneSignal, Braze             |
| 6 | Session replay + heatmaps      | Why did the user drop off / where do they tap?             | UXCam               | Smartlook, FullStory, LogRocket        |
| 7 | Remote config + A/B + flags    | Ship a change to 5% / a cohort without releasing           | Firebase Remote Cfg | Statsig, GrowthBook, LaunchDarkly      |
| 8 | Marketing pixels               | Optimise paid-ad audiences + conversions                   | Meta SDK            | Google Ads, TikTok, Snap, X            |
| 9 | Server-side / 1st-party events | Source of truth that survives ad-blockers + iOS opt-out    | Custom `/track` API | RudderStack, Snowplow, Segment server  |

> Recommended starter pack for SharePerks: **Firebase Analytics + Sentry +
> AppsFlyer + CleverTap + Firebase Remote Config + Meta SDK + a first-party
> `/track` ingestion endpoint.** Add UXCam later when we want behavioural
> debugging.

---

## 3. High-level architecture

```text
                       ┌────────────────────────────────────────┐
                       │              UI / Screens              │
                       │   (only ever calls AnalyticsService)   │
                       └────────────────────────────────────────┘
                                          │
                                          ▼
                       ┌────────────────────────────────────────┐
                       │  lib/integrations/analytics/           │
                       │  AnalyticsService  (single facade)     │
                       │   • track(event, props)                │
                       │   • screen(name, props)                │
                       │   • identify(user)                     │
                       │   • setUserProperty(k, v)              │
                       │   • reset()                            │
                       └────────────────────────────────────────┘
                                          │  fan-out
        ┌────────────────┬────────────────┼────────────────┬────────────────┐
        ▼                ▼                ▼                ▼                ▼
 FirebaseSink      SentrySink     AppsFlyerSink    CleverTapSink     ServerSink
 (events,          (errors,       (installs,        (push, journeys,  (POST /track
  user props,       traces)        deeplinks,        in-app msgs)      to backend)
  remote cfg)                      revenue)
        │
        ▼
  Meta / Google / TikTok pixels (optional sinks toggled by RemoteConfig)
```

Key principles:

- **No screen ever imports a vendor SDK.** They only import
  `AnalyticsService`. Swapping or adding vendors is a 1-file change.
- **Every sink is optional + lazy-initialised.** A missing / broken SDK must
  never crash the app — wrap everything in `try/catch` and log via the existing
  `logger`.
- **Consent-gated.** No PII / advertising-id leaves the device until the user
  passes the consent gate (see §10).
- **Same taxonomy everywhere.** The event name + props that go to Firebase are
  the same that go to CleverTap, our backend, and Meta. This is what makes
  funnel + retention analysis possible across tools.

---

## 4. Mapping tracking layers to the SharePerks codebase

The app already exposes the right hook points — we just need to attach to them.

| Where in the app                                                  | What we attach                                                                 |
|-------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `lib/main.dart` → `main()`                                        | Initialise every sink (Firebase, Sentry, AppsFlyer, CleverTap) before `runApp` |
| `lib/main.dart` → `didChangeAppLifecycleState`                    | Emit `app_foregrounded` / `app_backgrounded`                                    |
| `lib/constants/routes.dart` → `StarvestRouteObserver`             | Emit `screen_view` on every `didPush` / `didReplace`                            |
| `lib/constants/routes.dart` → `onEnter`                           | Emit `route_blocked` (no-internet, force-update)                                |
| `lib/repository/network.dart` → Dio interceptors                  | Emit `api_error`, attach Sentry breadcrumbs, time API calls                     |
| `lib/repository/services/auth/auth_service.dart`                  | `identify(user)` after `verifyOtp` / `verifySession` / `completeProfile`        |
| `lib/repository/providers/user.provider.dart` → `clearUser()`     | `AnalyticsService.reset()` on logout                                            |
| `lib/screens/landing/*`                                           | Onboarding funnel events (see §6)                                               |
| `lib/screens/main/HomeScreen.dart` & related                      | Discovery / browse events                                                       |
| `lib/screens/rewards/*` + `lib/screens/rewards/giftcard/*`        | Reward + gift-card redemption funnel                                            |
| `lib/integrations/cashfree_payment.dart`                          | Payment lifecycle events + revenue                                              |
| `lib/screens/payments/*` (`Wallet`, `Earning`, `Payout`)          | Money-out funnel                                                                |
| `lib/screens/refer/*`                                             | Referral funnel + share intent                                                  |
| `lib/screens/holding/*`                                           | Demat-link / holding-import funnel                                              |

---

## 5. Proposed folder structure

```text
lib/integrations/analytics/
├── analytics_service.dart          // The public facade
├── analytics_event.dart            // Sealed class / enum of all event names
├── analytics_user.dart             // User-property keys + DTO
├── consent_manager.dart            // Reads / writes consent flags via LocalStorage
├── route_observer.dart             // GoRouter / Navigator observer → screen events
├── sinks/
│   ├── analytics_sink.dart         // Abstract interface
│   ├── firebase_sink.dart
│   ├── sentry_sink.dart
│   ├── appsflyer_sink.dart
│   ├── clevertap_sink.dart
│   ├── meta_sink.dart
│   ├── server_sink.dart            // POSTs to https://api.shareperks.in/track
│   └── debug_sink.dart             // Pretty-prints in kDebugMode only
└── README.md                       // Quick-ref of event names + props
```

`AnalyticsService` reference skeleton:

```dart
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final List<AnalyticsSink> _sinks = [];
  bool _consentGiven = false;

  Future<void> init() async {
    _sinks.addAll([
      if (kDebugMode) DebugSink(),
      FirebaseSink(),
      SentrySink(),
      AppsFlyerSink(),
      CleverTapSink(),
      ServerSink(),
    ]);
    for (final s in _sinks) {
      try { await s.init(); } catch (e, st) { logger.e('sink init', error: e, stackTrace: st); }
    }
    _consentGiven = await ConsentManager.isGranted();
  }

  Future<void> identify(UserModel user) async {
    for (final s in _sinks) {
      try { await s.identify(user); } catch (_) {}
    }
  }

  Future<void> track(AnalyticsEvent event, [Map<String, Object?> props = const {}]) async {
    if (!_consentGiven && event.requiresConsent) return;
    for (final s in _sinks) {
      try { await s.track(event.name, props); } catch (_) {}
    }
  }

  Future<void> screen(String name, [Map<String, Object?> props = const {}]) async {
    for (final s in _sinks) {
      try { await s.screen(name, props); } catch (_) {}
    }
  }

  Future<void> reset() async {
    for (final s in _sinks) {
      try { await s.reset(); } catch (_) {}
    }
  }
}
```

---

## 6. SharePerks event taxonomy (v1)

Every event is `lower_snake_case`. Properties are also `lower_snake_case`. We
keep the list small and intentional — it is far better to have 30 well-defined
events than 200 noisy ones.

### 6.1 App lifecycle

| Event                 | Trigger                                                | Key props                                  |
|-----------------------|--------------------------------------------------------|--------------------------------------------|
| `app_opened`          | First frame of app run (cold start)                    | `is_first_open`, `from_deeplink`, `source` |
| `app_foregrounded`    | `AppLifecycleState.resumed`                            | `paused_for_ms`                            |
| `app_backgrounded`    | `AppLifecycleState.paused`                             | —                                          |
| `screen_view`         | `StarvestRouteObserver.didPush`                        | `screen_name`, `previous_screen`           |
| `deeplink_opened`     | App launched / resumed via universal link              | `url`, `path`, `utm_*`                     |
| `force_update_shown`  | `NewUpdateScreen` rendered                             | `current_version`, `min_version`           |
| `connectivity_lost`   | `Connectivity().onConnectivityChanged` → none          | —                                          |

### 6.2 Onboarding & auth funnel

| Event                       | Trigger                                                |
|-----------------------------|---------------------------------------------------------|
| `landing_viewed`            | `LandingScreen` mount                                  |
| `login_started`             | User taps "Login" / enters mobile field                |
| `otp_sent`                  | `AuthService.login` returns success                    |
| `otp_resent`                | User taps "Resend OTP"                                 |
| `otp_verified`              | `AuthService.verifyOtp` returns token                  |
| `otp_failed`                | `verifyOtp` returns `success != true`                  |
| `profile_setup_started`     | `SetupScreen` mount                                    |
| `profile_completed`         | `AuthService.completeProfile` success                  |
| `signup_completed`          | First time `profile_completed` for a new userId        |
| `logout`                    | `clearUser()` called                                   |

### 6.3 Discovery / browse

| Event                       | Key props                                                          |
|-----------------------------|---------------------------------------------------------------------|
| `home_loaded`               | `latency_ms`, `is_error`                                            |
| `category_viewed`           | `category_id`                                                       |
| `brand_viewed`              | `brand_id`, `source` (e.g. `home`, `top_brands`, `search`)          |
| `company_viewed`            | `company_id`, `source`                                              |
| `top_perks_viewed`          | `count`                                                             |
| `top_brands_viewed`         | `count`                                                             |
| `perk_type_viewed`          | `type` (`cashback` / `giftcard` / `promocode`)                      |
| `unlocked_perks_viewed`     | `count`                                                             |
| `perk_card_clicked`         | `perk_id`, `perk_type`, `brand_id`, `position`, `source`            |
| `request_perk_submitted`    | `brand_name`, `category`                                            |
| `voting_brand_selected`     | `brand_id`                                                          |

### 6.4 Reward / redemption funnel — Gift Card

This is the **revenue funnel** and must be instrumented end-to-end:

```
giftcard_perk_viewed
   → giftcard_eligibility_checked        (eligible? true/false)
       → giftcard_amount_screen_viewed
           → giftcard_amount_selected    (amount, denomination_type)
               → giftcard_payment_initiated  (cashfree_order_id, amount)
                   → giftcard_payment_succeeded   ✅  revenue event
                   → giftcard_payment_failed      ❌  reason, error_code
                       → giftcard_payment_retried
giftcard_redeemed_code_viewed
giftcard_code_copied
```

`giftcard_payment_succeeded` should also be sent to **AppsFlyer**, **Meta**,
and **Google Ads** as a `purchase` revenue event with `currency` + `value`.

### 6.5 Reward / redemption funnel — Cashback & Promo

| Event                         | Notes                                              |
|-------------------------------|-----------------------------------------------------|
| `cashback_perk_viewed`        | `reward_id`                                        |
| `cashback_terms_read`         | `content_id`                                       |
| `cashback_claim_started`      |                                                     |
| `cashback_claim_completed`    | revenue event                                       |
| `promocode_perk_viewed`       | `reward_id`                                        |
| `promocode_revealed`          | `reward_id`                                        |
| `promocode_copied`            | `reward_id`                                        |

### 6.6 Demat-link / holding funnel

| Event                       | Trigger                                                      |
|-----------------------------|---------------------------------------------------------------|
| `link_demat_started`        | `LinkDematInfoScreen` view                                   |
| `broker_list_viewed`        | `ListBrokersScreen` view                                     |
| `broker_selected`           | `broker_id`                                                  |
| `smallcase_gateway_opened`  | `lib/integrations/smallcase_gateway.dart`                    |
| `smallcase_gateway_success` | callback                                                     |
| `smallcase_gateway_failed`  | callback + reason                                            |
| `holding_statement_uploaded`| filename, file_size, broker_name                             |
| `holdings_synced`           | num_holdings                                                 |

### 6.7 Wallet & payout funnel

| Event                 | Key props                              |
|-----------------------|----------------------------------------|
| `wallet_viewed`       | `balance`                              |
| `earning_viewed`      | `total_earned`                         |
| `wallet_history_viewed`| —                                     |
| `payout_started`      | `amount`                               |
| `payout_request_submitted` | `amount`, `method`                |
| `payout_succeeded`    | `amount`, `txn_id`                     |
| `payout_failed`       | `amount`, `reason`                     |

### 6.8 Referral funnel (critical for growth)

| Event                  | Key props                                |
|------------------------|------------------------------------------|
| `refer_screen_viewed`  | `referral_code`                          |
| `refer_code_copied`    | `referral_code`                          |
| `refer_share_intent`   | `channel` (whatsapp/sms/system)          |
| `refer_link_opened`    | server-side, when invitee installs       |
| `refer_signup_completed`| server-side, when invitee finishes onboarding |
| `refer_reward_credited`| server-side, when payout fires           |

### 6.9 Notifications & engagement

| Event                          |
|--------------------------------|
| `push_token_registered`        |
| `push_received`                |
| `push_opened` (with `campaign_id`) |
| `notification_screen_viewed`   |
| `inapp_message_shown`          |
| `inapp_message_clicked`        |

### 6.10 Errors & diagnostics

| Event                  | Notes                                        |
|------------------------|----------------------------------------------|
| `api_error`            | `endpoint`, `status_code`, `error_code`      |
| `app_error`            | non-fatal Flutter error, also sent to Sentry |
| `network_timeout`      | Dio timeout in interceptor                   |

---

## 7. User identity model

After `AuthService.verifyOtp` / `verifySession`, call
`AnalyticsService.instance.identify(user)`. Every sink maps the same fields:

| Sink            | userId           | extras                                       |
|-----------------|------------------|----------------------------------------------|
| Firebase        | `setUserId`      | `setUserProperty(k, v)`                      |
| Sentry          | `Sentry.configureScope` → `setUser`           |                                              |
| AppsFlyer       | `setCustomerUserId`            |                                              |
| CleverTap       | `onUserLogin({Identity, Email, Phone, ...})`  |                                              |
| Server sink     | header `X-User-Id` + `X-Anon-Id`              |                                              |

### User properties (sticky — set once, updated when changed)

```text
user_id                 // backend id
phone_hashed            // SHA-256 for marketing pixels
email_hashed
name                    // first name only, for personalisation
signup_date             // ISO yyyy-MM-dd
days_since_signup
is_profile_complete     // bool
is_demat_linked         // bool
linked_brokers_count    // int
holdings_value_bucket   // "0", "<10k", "10k-1L", "1L-10L", ">10L"
wallet_balance_bucket   // bucketed, never raw
total_earned_bucket
total_redeemed_bucket
referral_code           // own code
referred_by             // inviter code, if any
referrals_completed     // count
last_active_at          // ISO timestamp
preferred_language
```

> Bucketing money values (instead of sending raw amounts) is a privacy +
> cardinality best practice. Backends still get raw values via `ServerSink`.

### Anonymous → identified merging

- On first launch, generate a UUID and store it via `LocalStorage` as
  `anon_id`.
- Send `anon_id` on every event before login.
- After `identify(user)`, send both `user_id` and `anon_id` so the warehouse
  can stitch the pre-login session to the user.

---

## 8. Screen tracking via the existing route observer

The router already has `StarvestRouteObserver`. We extend it (don't replace —
keep the existing `print` for debug):

```dart
final class StarvestRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = _routeLabel(route);
    AnalyticsService.instance.screen(name, {
      'previous_screen': previousRoute != null ? _routeLabel(previousRoute) : null,
    });
  }
  // didPop already implemented
}
```

`GoRouter.onEnter` is also a good place to fire `route_blocked` whenever we
intercept (no-internet redirect, force-update redirect).

---

## 9. Network + crash + performance instrumentation

### 9.1 Dio interceptor (extend `lib/repository/network.dart`)

```dart
onRequest: (options, handler) {
  options.extra['t0'] = DateTime.now().millisecondsSinceEpoch;
  ...
},
onResponse: (response, handler) {
  final t0 = response.requestOptions.extra['t0'] as int?;
  AnalyticsService.instance.track(AnalyticsEvent.apiCall, {
    'endpoint': response.requestOptions.path,
    'method'  : response.requestOptions.method,
    'status'  : response.statusCode,
    'latency_ms': t0 != null ? DateTime.now().millisecondsSinceEpoch - t0 : null,
  });
  ...
},
onError: (error, handler) {
  AnalyticsService.instance.track(AnalyticsEvent.apiError, {
    'endpoint': error.requestOptions.path,
    'status'  : error.response?.statusCode,
    'message' : error.message,
  });
  Sentry.captureException(error, stackTrace: error.stackTrace);
  ...
},
```

### 9.2 Crash reporting (Sentry)

In `main.dart`:

```dart
await SentryFlutter.init(
  (o) {
    o.dsn = Env.sentryDsn;
    o.tracesSampleRate = 0.2;       // 20% perf traces
    o.profilesSampleRate = 0.1;
    o.environment = kReleaseMode ? 'production' : 'debug';
    o.release = '${packageInfo.version}+${packageInfo.buildNumber}';
  },
  appRunner: () => runApp(...),
);

FlutterError.onError = (details) {
  Sentry.captureException(details.exception, stackTrace: details.stack);
  AnalyticsService.instance.track(AnalyticsEvent.appError, {
    'message': details.exceptionAsString(),
  });
};
PlatformDispatcher.instance.onError = (error, stack) {
  Sentry.captureException(error, stackTrace: stack);
  return true;
};
```

### 9.3 Performance traces

Create a Sentry / Firebase Performance trace for:

- `home_load` — `HomeScreen.loadData`
- `gift_card_payment` — wraps Cashfree order + redirect + verify
- `holding_upload` — `UploadHoldingStatementScreen`
- Any screen whose first paint takes >2s

---

## 10. Privacy, consent & store policy

This is mandatory — get it wrong and Apple will reject the build.

### 10.1 iOS — App Tracking Transparency (ATT)

`ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this to personalise perks and measure how you discover SharePerks.</string>
```

Trigger ATT prompt **only** before initialising AppsFlyer / Meta:

```dart
final status = await AppTrackingTransparency.requestTrackingAuthorization();
final canTrackAds = status == TrackingStatus.authorized;
```

If `canTrackAds == false`: skip AppsFlyer device-id, Meta IDFA, and TikTok
pixel — but Firebase Analytics, CleverTap (without ad-id), Sentry, and our
own server-side events are still allowed.

### 10.2 Android — Ad ID permission

`android/app/src/main/AndroidManifest.xml` already exists. For SDK 33+:

```xml
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
```

Declare AD_ID usage in the Play Data Safety form.

### 10.3 India DPDP + GDPR consent gate

- A `consent_v1` flag in `LocalStorage` with values `granted` / `denied` /
  `unknown`.
- On first launch, show a sheet: "Help us improve SharePerks by sharing
  anonymous usage data." → CTA `Allow` / `Not now`.
- `AnalyticsService.track` skips events tagged `requiresConsent: true` until
  `granted`.
- Always-on, non-consent-gated events (allowed under legitimate-interest):
  crash reports without PII, security events, payment receipts.

### 10.4 PII rules

- **Never** put raw email / phone / DOB into a Firebase `event_param` or a
  CleverTap event property — they end up in pixels.
- **Always** hash PII with SHA-256 before sending to ad pixels (Meta CAPI,
  Google Enhanced Conversions).
- Raw PII only ever lives in CleverTap profile fields and on our backend.

---

## 11. Vendor pick — quick rationale

| Layer                | Pick               | Why for SharePerks                                                                |
|----------------------|--------------------|------------------------------------------------------------------------------------|
| Product analytics    | **Firebase**       | Free, integrates with Crashlytics, Remote Config, Cloud Messaging                 |
| Crash + perf         | **Sentry**         | Better DX than Crashlytics, Flutter symbolication, integrates with our backend    |
| Attribution          | **AppsFlyer**      | Strongest in India for fintech / rewards, fraud protection, deeplink + OneLink    |
| Push + journeys      | **CleverTap**      | Indian SaaS with strong segmentation; competitive pricing vs Braze / MoEngage     |
| Remote config / flags| **Firebase RC**    | Already in the Firebase suite; `force_update` config maps directly to our flow    |
| Marketing pixels     | **Meta + Google**  | Where most paid spend will go; both have Conversions API for server-side          |
| Server-side          | **Custom + Rudder**| First-party `/track` route; RudderStack to fan-out events without re-instrumenting |
| Session replay       | **UXCam** *(later)*| Add when we have ≥ 50k MAU and need behavioural debugging                         |

---

## 12. Recommended Flutter packages

Add to `pubspec.yaml` only the layers you ship:

```yaml
dependencies:
  # Product analytics + remote config + crash + perf (Google stack)
  firebase_core: ^3.6.0
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0
  firebase_performance: ^0.10.0
  firebase_remote_config: ^5.1.0
  firebase_messaging: ^15.1.0

  # Sentry (preferred over Crashlytics for our team)
  sentry_flutter: ^8.10.0

  # Attribution
  appsflyer_sdk: ^6.16.0

  # Lifecycle CRM + push
  clevertap_plugin: ^3.3.0

  # Marketing
  facebook_app_events: ^0.20.0

  # Privacy
  app_tracking_transparency: ^2.0.6

  # Optional later
  uxcam: ^2.4.0
```

> Pick **either** Firebase Crashlytics **or** Sentry — running both duplicates
> crash volume and bloats the binary.

---

## 13. Implementation roadmap

| Phase | Scope                                                                                         | ETA   |
|-------|------------------------------------------------------------------------------------------------|-------|
| 0     | Land this README, agree on event taxonomy, create `lib/integrations/analytics/` skeleton      | day 1 |
| 1     | Firebase Analytics + Sentry + ServerSink + screen-view auto-tracking via route observer       | week 1|
| 2     | Auth funnel + reward funnel + payment events instrumented; identify() wired                   | week 2|
| 3     | AppsFlyer + OneLink deferred-deeplink + referral attribution                                  | week 3|
| 4     | CleverTap + push notifications + onboarding journey                                           | week 4|
| 5     | Firebase Remote Config (force-update, feature flags) + first A/B test                         | week 5|
| 6     | Meta + Google Ads pixels with hashed PII + Conversions API on backend                         | week 6|
| 7     | UXCam (gated rollout) + funnel dashboards in Mixpanel-style explore tool                      | later |

---

## 14. Quick FAQ

**Q: Why a facade instead of calling Firebase directly?**
We will swap or add vendors. Already there's a 70% chance we add CleverTap and
AppsFlyer in week 3-4. Doing that without a facade means touching every screen.

**Q: Why both client-side + server-side tracking?**
Client-side dies under ad-blockers, iOS opt-out, and network drops. Server-side
sees every successful API call (our source of truth for revenue, payouts,
referrals). Use both, reconcile in the warehouse.

**Q: Where do I put a new event?**
1. Add it to `analytics_event.dart` (with description + props).
2. Call `AnalyticsService.instance.track(...)` at the trigger point.
3. Append it to §6 of this README.

**Q: How do we avoid event-name drift?**
`AnalyticsEvent` is a sealed class / enum. The only way to fire an event is
through that type — string literals are forbidden in screens.

**Q: How do we test tracking?**
- `DebugSink` pretty-prints every event to the logger in `kDebugMode`.
- Firebase `DebugView` for verifying live events.
- Sentry has a `--release` tag we set per build.
- Add a hidden 5-tap gesture on the splash screen to open an in-app event log
  (helpful for QA on real devices).

---

## 15. Glossary

- **Sink** — a destination an event is sent to (Firebase, Sentry, our backend).
- **Identify** — telling every sink "this anon device is now this user".
- **Funnel** — an ordered list of events used to measure drop-off.
- **Cohort** — group of users who share a property (e.g. signed up in March).
- **Attribution** — which campaign / channel / referrer is credited for an
  install or conversion.
- **CAPI / S2S** — Conversions API / server-to-server pixel; how we send
  conversions to ad networks bypassing the device.

---

_Last updated: 2026-05-26 — owner: SharePerks app team. Update this doc in the
same PR that introduces a new event or vendor._
