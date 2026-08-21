import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import '../analytics_event.dart';
import '../campaign_attribution.dart';
import 'analytics_sink.dart';

/// Forwards [AnalyticsService] events to Meta App Events (Facebook SDK).
///
/// Screens must never import `facebook_app_events` — only this sink does.
class MetaSink implements AnalyticsSink {
  FacebookAppEvents? _fb;
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
  String get name => 'meta';

  @override
  Future<void> init() async {
    try {
      _fb = FacebookAppEvents();
      // Advertiser ID / auto-log stay off until ATT + consent are applied.
      await _fb!.setAutoLogAppEventsEnabled(false);
      await _fb!.setAdvertiserIdCollectionEnabled(false);
      if (kDebugMode) {
        final id = await _fb!.getApplicationId();
        debugPrint('[analytics] MetaSink ready appId=$id');
      }
    } catch (e, st) {
      debugPrint('[analytics] MetaSink init failed: $e\n$st');
      _fb = null;
    }
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> props) async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.setUserID(userId);
    } catch (e) {
      debugPrint('[analytics] MetaSink.identify failed: $e');
    }
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    // Meta App Events has no general user-property API like Firebase.
  }

  @override
  Future<void> track(
    AnalyticsEvent event,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    final fb = _fb;
    if (fb == null) return;
    try {
      final params = _sanitize({
        ...CampaignAttribution.asEventProps(),
        ...ctx,
        ...props,
      });
      await _emitStandard(fb, event, params);
      await fb.logEvent(
        name: _eventName(event.name),
        parameters: params,
      );
    } catch (e) {
      debugPrint('[analytics] MetaSink.track failed: $e');
    }
  }

  @override
  Future<void> screen(
    String screenName,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.logEvent(
        name: 'fb_mobile_content_view',
        parameters: _sanitize({
          'fb_content_type': 'screen',
          'fb_content_id': screenName,
          'screen_name': screenName,
          ...CampaignAttribution.asEventProps(),
          ...ctx,
          ...props,
        }),
      );
    } catch (e) {
      debugPrint('[analytics] MetaSink.screen failed: $e');
    }
  }

  @override
  Future<void> reset() async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.clearUserID();
      await fb.clearUserData();
    } catch (e) {
      debugPrint('[analytics] MetaSink.reset failed: $e');
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
    final fb = _fb;
    if (fb == null) return;
    try {
      // SKAN / aggregated measurement is allowed after the ATT decision,
      // including when the user taps "Ask App Not to Track".
      await fb.activateApp();
    } catch (e) {
      debugPrint('[analytics] MetaSink.activateApp failed: $e');
    }
  }

  Future<void> _applyPrivacyFlags() async {
    final fb = _fb;
    if (fb == null) return;
    try {
      await fb.setAutoLogAppEventsEnabled(_consentGranted);
      await fb.setAdvertiserIdCollectionEnabled(
        _consentGranted && _trackingAuthorized,
      );
      await fb.setLimitEventAndDataUsage(!_trackingAuthorized);
      if (_trackingAuthorized && _consentGranted) {
        await fb.setDataProcessingOptions([]);
      } else {
        await fb.setDataProcessingOptions(['LDU'], country: 0, state: 0);
      }
      debugPrint(
        '[analytics] MetaSink privacy consent=$_consentGranted '
        'att=$_trackingAuthorized',
      );
    } catch (e) {
      debugPrint('[analytics] MetaSink privacy flags failed: $e');
    }
  }

  Future<void> _emitStandard(
    FacebookAppEvents fb,
    AnalyticsEvent event,
    Map<String, dynamic> params,
  ) async {
    switch (event.name) {
      case 'new_user':
        await fb.logCompletedRegistration(
          registrationMethod: _string(params['method']) ?? 'otp',
          parameters: params,
        );
        break;
      case 'login':
        await fb.logEvent(name: 'Login', parameters: params);
        break;
      case 'logout':
        await fb.logEvent(name: 'Logout', parameters: params);
        break;
      case 'search':
        final term = _string(params['search_term'] ?? params['query']);
        if (term != null && term.isNotEmpty) {
          await fb.logEvent(
            name: FacebookAppEvents.eventNameSearched,
            parameters: {
              ...params,
              FacebookAppEvents.paramNameSearchString: term,
            },
          );
        }
        break;
      case 'view_content':
        await fb.logViewContent(
          id: _string(params['item_id'] ??
              params['content_id'] ??
              params['reward_id'] ??
              params['brand_id']),
          type: _string(params['content_type'] ??
              params['item_category'] ??
              params['perk_type']) ??
              'product',
          currency: _string(params['currency']) ?? 'INR',
          price: _num(params['value'] ?? params['amount']),
          parameters: params,
        );
        break;
      case 'giftcard_payment_succeeded':
        final amount = _num(params['amount'] ??
            params['selected_amount'] ??
            params['payable_amount'] ??
            params['value']);
        if (amount != null) {
          await fb.logPurchase(
            amount: amount,
            currency: _string(params['currency']) ?? 'INR',
            parameters: params,
          );
        }
        break;
      case 'giftcard_payment_initiated':
      case 'giftcard_checkout_opened':
        await fb.logInitiatedCheckout(
          totalPrice: _num(params['amount'] ?? params['selected_amount']),
          currency: _string(params['currency']) ?? 'INR',
          parameters: params,
        );
        break;
      case 'app_opened':
        await fb.activateApp();
        if (params['is_first_open'] == true ||
            params['is_first_open'] == 'true') {
          await fb.logEvent(name: 'fb_mobile_activate_app', parameters: params);
        }
        break;
      case 'install_attributed':
        await fb.logEvent(name: 'fb_mobile_activate_app', parameters: params);
        break;
      case 'deeplink_opened':
        await fb.logEvent(name: 'fb_mobile_deeplink', parameters: params);
        break;
    }
  }

  Map<String, dynamic> _sanitize(Map<String, Object?> raw) {
    final out = <String, dynamic>{};
    for (final e in raw.entries) {
      if (out.length >= 25) break;
      final key = e.key.toLowerCase();
      if (_piiKeys.contains(key)) continue;
      final v = e.value;
      if (v == null) continue;
      if (v is bool || v is num || v is String) {
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
    return _truncate(cleaned, 40);
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
