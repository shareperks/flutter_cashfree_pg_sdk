# Screen instrumentation — copy into Flutter app

Copy the updated analytics package from `docs/flutter/integrations/analytics/` into `application/lib/integrations/analytics/`, then apply the snippets below to each screen file.

Master spec: [`docs/user-audit-system.md`](../../user-audit-system.md).

## Shared imports

```dart
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/journey_context.dart';
import 'package:shareperks/integrations/analytics/track_eligibility.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
```

## P0 — Home (`lib/screens/main/HomeScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  _loadHome();
}

Future<void> _loadHome() async {
  final sw = Stopwatch()..start();
  try {
    // ... existing home fetch ...
    await trackAction(AnalyticsEvent.homeLoaded, {
      'latency_ms': sw.elapsedMilliseconds,
      'is_error': false,
    });
  } catch (_) {
    await trackAction(AnalyticsEvent.homeLoaded, {
      'latency_ms': sw.elapsedMilliseconds,
      'is_error': true,
    });
    rethrow;
  }
}

void _onPerkTap(Reward reward, int position) {
  JourneyContext.startJourney(
    rewardId: reward.id,
    perkType: reward.type.toLowerCase(), // giftcard | promocode | cashback
  );
  trackAction(AnalyticsEvent.perkCardClicked, {
    'reward_id': reward.id,
    'perk_type': reward.type.toLowerCase(),
    'position': position,
    'source': 'home',
    if (reward.brandId != null) 'brand_id': reward.brandId!,
  });
  // ... existing navigation ...
}
```

## P0 — Gift card detail (`lib/screens/rewards/GiftCardRewardScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  if (JourneyContext.currentJourneyId == null) {
    JourneyContext.startJourney(
      rewardId: widget.rewardId,
      perkType: 'giftcard',
    );
  }
  trackAction(AnalyticsEvent.giftcardPerkViewed, {
    'reward_id': widget.rewardId,
    'brand_id': widget.brandId,
    'source': widget.source ?? 'unknown',
  });
}

Future<void> _checkEligibility() async {
  final result = await /* existing eligibility API */;
  await trackEligibility(
    perkType: 'giftcard',
    rewardId: widget.rewardId,
    isEligible: result.isEligible,
    reason: result.reason, // no_holdings | expired | ok
    source: 'reward_detail',
    brandId: widget.brandId,
  );
}
```

## P0 — Gift card amount (`lib/screens/rewards/giftcard/GiftCardAmountScreen.dart`)

```dart
bool _paymentStarted = false;
bool _paymentFinished = false;
num? _selectedAmount;

@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.giftcardAmountScreenViewed, {
    'reward_id': widget.rewardId,
    'is_eligible': widget.isEligible,
  });
}

void _onAmountSelected(num amount) {
  _selectedAmount = amount;
  trackAction(AnalyticsEvent.giftcardAmountSelected, {
    'amount': amount,
    'denomination_type': widget.denominationType,
  });
}

Future<void> _startPayment() async {
  _paymentStarted = true;
  trackAction(AnalyticsEvent.giftcardPaymentInitiated, {
    'amount': _selectedAmount,
    'credit_id': widget.creditId,
    'journey_id': JourneyContext.currentJourneyId,
  });
  // Pass journey_id to backend:
  // POST /payment/giftcard/proceed body includes journey_id
  // ... existing Cashfree flow ...
}

@override
void dispose() {
  if (_paymentStarted && !_paymentFinished) {
    trackAction(AnalyticsEvent.giftcardPaymentAbandoned, {
      'abandon_stage': 'amount_screen',
      if (_selectedAmount != null) 'selected_amount': _selectedAmount!,
    });
  }
  super.dispose();
}
```

## P0 — Payment success (`lib/screens/rewards/giftcard/PaymentSucessScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.giftcardPaymentSucceeded, {
    'cashfree_order_id': widget.orderId,
    'amount': widget.amount,
    'credit_id': widget.creditId,
  });
  JourneyContext.clearJourney();
}
```

## P0 — Promocode (`lib/screens/rewards/PromoCodeRewardScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  if (JourneyContext.currentJourneyId == null) {
    JourneyContext.startJourney(
      rewardId: widget.offerId,
      perkType: 'promocode',
    );
  }
  trackAction(AnalyticsEvent.promocodePerkViewed, {
    'reward_id': widget.offerId,
    'brand_id': widget.brandId,
  });
}

Future<void> _onRevealTap() async {
  final eligible = /* existing check */;
  await trackEligibility(
    perkType: 'promocode',
    rewardId: widget.offerId,
    isEligible: eligible,
    reason: eligible ? 'ok' : 'not_eligible',
    source: 'reward_detail',
    brandId: widget.brandId,
  );
  if (!eligible) {
    await trackAction(AnalyticsEvent.promocodeRevealBlocked, {
      'reason': 'not_eligible',
    });
    return;
  }
  // ... existing claim API — server emits promocode_revealed ...
  await trackAction(AnalyticsEvent.promocodeRevealed, {
    'reward_id': widget.offerId,
  });
}
```

## Lifecycle — enriched `app_backgrounded` (`main.dart`)

```dart
case AppLifecycleState.paused:
  AnalyticsService.instance.track(
    AnalyticsEvent.appBackgrounded,
    AnalyticsService.instance.backgroundProps(),
  );
  AnalyticsService.instance.flush();
  break;
```
