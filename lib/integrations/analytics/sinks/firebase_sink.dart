import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../analytics_event.dart';
import '../campaign_attribution.dart';
import '../google_conversions.dart';
import 'analytics_sink.dart';

/// Forwards [AnalyticsService] events to Firebase Analytics (GA4).
///
/// Never throws — a broken Firebase SDK must not crash the app.
/// Strips raw PII (`mobile`, `email`, `phone`) before sending.
class FirebaseSink implements AnalyticsSink {
  FirebaseAnalytics? _ga;

  static const _piiKeys = {
    'mobile',
    'email',
    'phone',
    'phone_number',
    'password',
    'otp',
    'token',
  };

  @override
  String get name => 'firebase';

  @override
  Future<void> init() async {
    try {
      _ga = FirebaseAnalytics.instance;
      await _pushDefaultCampaignParams();
      if (kDebugMode) {
        debugPrint(
          '[analytics] FirebaseSink ready conversions=${GoogleConversions.conversionEventNames}',
        );
      }
    } catch (e, st) {
      debugPrint('[analytics] FirebaseSink init failed: $e\n$st');
      _ga = null;
    }
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> props) async {
    final ga = _ga;
    if (ga == null) return;
    try {
      await ga.setUserId(id: userId);
      for (final e in _sanitize(props).entries) {
        await ga.setUserProperty(name: _truncate(e.key, 24), value: '${e.value}');
      }
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.identify failed: $e');
    }
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    final ga = _ga;
    if (ga == null || value == null) return;
    if (_piiKeys.contains(key.toLowerCase())) return;
    try {
      await ga.setUserProperty(name: _truncate(key, 24), value: '$value');
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.setUserProperty failed: $e');
    }
  }

  @override
  Future<void> track(
    AnalyticsEvent event,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    final ga = _ga;
    if (ga == null) return;
    try {
      final params = _sanitize({
        ...CampaignAttribution.asEventProps(),
        ...ctx,
        ...props,
      });
      await _emitRecommended(ga, event, params);
      await ga.logEvent(
        name: _eventName(event.name),
        parameters: params,
      );
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.track failed: $e');
    }
  }

  @override
  Future<void> screen(
    String screenName,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    final ga = _ga;
    if (ga == null) return;
    try {
      await ga.logScreenView(
        screenName: _truncate(screenName, 100),
        parameters: _sanitize({
          ...CampaignAttribution.asEventProps(),
          ...ctx,
          ...props,
        }),
      );
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.screen failed: $e');
    }
  }

  @override
  Future<void> reset() async {
    final ga = _ga;
    if (ga == null) return;
    try {
      await ga.setUserId(id: null);
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.reset failed: $e');
    }
  }

  @override
  Future<void> onConsentChanged(bool granted) async {
    final ga = _ga;
    if (ga == null) return;
    try {
      // Google Consent Mode v2 — set before Ads / Analytics use of storage.
      await ga.setConsent(
        analyticsStorageConsentGranted: granted,
        adStorageConsentGranted: granted,
        adUserDataConsentGranted: granted,
        adPersonalizationSignalsConsentGranted: granted,
      );
      await ga.setAnalyticsCollectionEnabled(granted);
    } catch (e) {
      debugPrint('[analytics] FirebaseSink.onConsentChanged failed: $e');
    }
  }

  Future<void> _pushDefaultCampaignParams() async {
    final ga = _ga;
    if (ga == null) return;
    final campaign = _sanitize(CampaignAttribution.asEventProps());
    if (campaign.isEmpty) return;
    try {
      await ga.setDefaultEventParameters(campaign);
    } catch (e) {
      debugPrint('[analytics] setDefaultEventParameters failed: $e');
    }
  }

  /// Maps key funnel events onto GA4 recommended events used for Ads conversions.
  Future<void> _emitRecommended(
    FirebaseAnalytics ga,
    AnalyticsEvent event,
    Map<String, Object> params,
  ) async {
    switch (event.name) {
      case 'signup_completed':
        await ga.logSignUp(signUpMethod: 'otp');
        break;
      case 'otp_verified':
        if (params['is_profile_complete'] == true ||
            params['is_profile_complete'] == 'true') {
          await ga.logLogin(loginMethod: 'otp');
        }
        break;
      case 'giftcard_payment_succeeded':
        await ga.logPurchase(
          currency: _string(params['currency']) ?? 'INR',
          value: _num(params['amount'] ??
              params['selected_amount'] ??
              params['payable_amount'] ??
              params['value']),
          transactionId: _string(params['order_id'] ??
              params['razorpay_order_id'] ??
              params['transaction_id']),
          parameters: params,
        );
        break;
      case 'app_opened':
        if (params['is_first_open'] == true ||
            params['is_first_open'] == 'true') {
          await ga.logEvent(name: 'sp_first_open', parameters: params);
        }
        break;
      case 'install_attributed':
        await ga.logEvent(name: 'campaign_details', parameters: params);
        break;
      case 'deeplink_opened':
        // Refresh sticky UTM defaults when a campaign deep link arrives.
        await _pushDefaultCampaignParams();
        break;
    }
  }

  Map<String, Object> _sanitize(Map<String, Object?> raw) {
    final out = <String, Object>{};
    for (final e in raw.entries) {
      if (out.length >= 25) break;
      final key = e.key.toLowerCase();
      if (_piiKeys.contains(key)) continue;
      if (key.length > 40) continue;
      final v = e.value;
      if (v == null) continue;
      if (v is bool) {
        out[e.key] = v ? 'true' : 'false';
      } else if (v is num || v is String) {
        out[e.key] = v is String ? _truncate(v, 100) : v;
      } else {
        out[e.key] = _truncate(v.toString(), 100);
      }
    }
    return out;
  }

  String _eventName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (cleaned.isEmpty) return 'custom_event';
    final withLetter = RegExp(r'^[a-zA-Z]').hasMatch(cleaned)
        ? cleaned
        : 'e_$cleaned';
    return _truncate(withLetter, 40);
  }

  String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  String? _string(Object? v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
