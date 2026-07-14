# Screen instrumentation — P1 and P2

Apply after P0 funnels are live. See [`p0-revenue-funnels.md`](p0-revenue-funnels.md) for shared imports.

## P1 — Cashback (`lib/screens/rewards/CashBackRewardScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  JourneyContext.startJourney(rewardId: widget.rewardId, perkType: 'cashback');
  trackAction(AnalyticsEvent.cashbackPerkViewed, {
    'reward_id': widget.rewardId,
    'brand_id': widget.brandId,
  });
}

Future<void> _onClaimTap() async {
  await trackEligibility(
    perkType: 'cashback',
    rewardId: widget.rewardId,
    isEligible: widget.isEligible,
    reason: widget.isEligible ? 'ok' : 'not_eligible',
    source: 'reward_detail',
    brandId: widget.brandId,
  );
  trackAction(AnalyticsEvent.cashbackClaimStarted, {
    'reward_id': widget.rewardId,
  });
  // ... open tracking link ...
  trackAction(AnalyticsEvent.cashbackClaimCompleted, {
    'reward_id': widget.rewardId,
  });
}
```

## P1 — Brand (`lib/screens/main/BrandViewScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.brandViewed, {
    'brand_id': widget.brandId,
    'source': widget.source ?? 'unknown',
  });
}
```

## P1 — Wallet (`lib/screens/payments/WalletScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.walletViewed, {});
}
```

## P1 — Payout (`lib/screens/payments/payout/PayoutScreen.dart`)

```dart
void _onPayoutStart() {
  trackAction(AnalyticsEvent.payoutStarted, {});
}

Future<void> _submitPayout() async {
  trackAction(AnalyticsEvent.payoutRequestSubmitted, {
    'amount': _amount,
  });
  // server also emits payout_request_submitted
}
```

## P1 — Demat (`lib/screens/info/LinkDematInfoScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.linkDematStarted, {
    'source': widget.source ?? 'ineligible_perk',
  });
}
```

## P1 — Broker list (`lib/screens/holding/ListBrokersScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.brokerListViewed, {});
}

void _onBrokerSelected(String brokerId) {
  trackAction(AnalyticsEvent.brokerSelected, {'broker_id': brokerId});
}
```

## P2 — Voting (`lib/feature/VotingBrands.dart`)

```dart
void _onBrandVote(String brandId, {required bool isRevote}) {
  trackAction(AnalyticsEvent.votingBrandSelected, {
    'brand_id': brandId,
    'is_revote': isRevote,
  });
}
```

## P2 — Referral (`lib/screens/refer/ReferAndEarnCodeScreen.dart`)

```dart
@override
void initState() {
  super.initState();
  trackAction(AnalyticsEvent.referScreenViewed, {});
}

void _onCopyCode() {
  trackAction(AnalyticsEvent.referCodeCopied, {});
}

void _onShare() {
  trackAction(AnalyticsEvent.referShareIntent, {});
}
```

## P2 — Push opened

```dart
void onNotificationOpened(Map<String, dynamic> data) {
  trackAction(AnalyticsEvent.pushOpened, {
    if (data['campaign_id'] != null) 'campaign_id': data['campaign_id'],
  });
}
```

## Dio interceptor (`lib/network/network.dart`)

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    options.extra['sw'] = Stopwatch()..start();
    handler.next(options);
  },
  onResponse: (response, handler) {
    final sw = response.requestOptions.extra['sw'] as Stopwatch?;
    AnalyticsService.instance.track(AnalyticsEvent.apiCall, {
      'endpoint': response.requestOptions.path,
      'status_code': response.statusCode,
      if (sw != null) 'latency_ms': sw.elapsedMilliseconds,
      ...AnalyticsService.instance.backgroundProps(),
    });
    handler.next(response);
  },
  onError: (e, handler) {
    AnalyticsService.instance.track(AnalyticsEvent.apiError, {
      'endpoint': e.requestOptions.path,
      'status_code': e.response?.statusCode,
      ...AnalyticsService.instance.backgroundProps(),
    });
    handler.next(e);
  },
));
```
