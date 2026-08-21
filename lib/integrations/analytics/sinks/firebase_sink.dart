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
  bool _consentGranted = false;
  bool _trackingAuthorized = false;

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
      final skipCustom = await _emitRecommended(ga, event, params);
      if (!skipCustom) {
        await ga.logEvent(
          name: _eventName(event.name),
          parameters: params,
        );
      }
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
    _consentGranted = granted;
    await _applyPrivacyFlags();
  }

  @override
  Future<void> onTrackingAuthorizationChanged(bool authorized) async {
    _trackingAuthorized = authorized;
    await _applyPrivacyFlags();
  }

  Future<void> _applyPrivacyFlags() async {
    final ga = _ga;
    if (ga == null) return;
    try {
      final ads = _consentGranted && _trackingAuthorized;
      await ga.setConsent(
        analyticsStorageConsentGranted: _consentGranted,
        adStorageConsentGranted: ads,
        adUserDataConsentGranted: ads,
        adPersonalizationSignalsConsentGranted: ads,
      );
      await ga.setAnalyticsCollectionEnabled(_consentGranted);
      debugPrint(
        '[analytics] FirebaseSink privacy consent=$_consentGranted '
        'att=$_trackingAuthorized ads=$ads',
      );
    } catch (e) {
      debugPrint('[analytics] FirebaseSink privacy flags failed: $e');
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
  ///
  /// Returns `true` when the recommended event already uses the same GA4 name
  /// as [event] (so the caller should skip a duplicate custom `logEvent`).
  Future<bool> _emitRecommended(
    FirebaseAnalytics ga,
    AnalyticsEvent event,
    Map<String, Object> params,
  ) async {
    switch (event.name) {
      case 'new_user':
        await ga.logSignUp(
          signUpMethod: _string(params['method']) ?? 'otp',
          parameters: params,
        );
        return false;
      case 'login':
        await ga.logLogin(
          loginMethod: _string(params['method']) ?? 'otp',
          parameters: params,
        );
        return true;
      case 'logout':
        await ga.logEvent(name: 'logout', parameters: params);
        return true;
      case 'search':
        final term = _string(params['search_term'] ?? params['query']) ?? '';
        if (term.isNotEmpty) {
          await ga.logSearch(searchTerm: term, parameters: params);
          return true;
        }
        return false;
      case 'view_content':
        await ga.logViewItem(
          currency: _string(params['currency']) ?? 'INR',
          value: _num(params['value'] ?? params['amount']),
          parameters: {
            ...params,
            if (_string(params['item_id'] ??
                    params['reward_id'] ??
                    params['brand_id']) !=
                null)
              'item_id': _string(params['item_id'] ??
                  params['reward_id'] ??
                  params['brand_id'])!,
            if (_string(params['item_name'] ??
                    params['reward_name'] ??
                    params['gift_card_name'] ??
                    params['brand_name']) !=
                null)
              'item_name': _string(params['item_name'] ??
                  params['reward_name'] ??
                  params['gift_card_name'] ??
                  params['brand_name'])!,
            if (_string(params['item_category'] ??
                    params['content_type'] ??
                    params['perk_type']) !=
                null)
              'item_category': _string(params['item_category'] ??
                  params['content_type'] ??
                  params['perk_type'])!,
          },
        );
        return false;
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
        return false;
      case 'app_opened':
        if (params['is_first_open'] == true ||
            params['is_first_open'] == 'true') {
          await ga.logEvent(name: 'sp_first_open', parameters: params);
        }
        return false;
      case 'install_attributed':
        await ga.logEvent(name: 'campaign_details', parameters: params);
        return false;
      case 'deeplink_opened':
        // Refresh sticky UTM defaults when a campaign deep link arrives.
        await _pushDefaultCampaignParams();
        return false;
      default:
        return false;
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
