import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';
import 'campaign_attribution.dart';

/// Reads Google Play Install Referrer once per install and forwards campaign
/// params to [CampaignAttribution] + GA4 (`campaign_details` / custom event).
///
/// This is Google Ads deferred attribution on Android (gclid / utm_* in the
/// referrer string). iOS deferred installs use SKAN / Google Ads — no Play API.
class InstallAttribution {
  InstallAttribution._();

  static const _seenKey = 'analytics_install_referrer_seen_v1';

  /// Call once after [AnalyticsService.init]. Safe on iOS (no-op).
  static Future<void> captureOnce() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_seenKey) == '1') return;

      final details = await PlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer ?? '';
      final params = CampaignAttribution.parseFromReferrerString(referrer);

      await prefs.setString(_seenKey, '1');

      if (params.isEmpty && referrer.isEmpty) {
        await AnalyticsService.instance.track(AnalyticsEvent.installAttributed, {
          'label': 'Install Referrer',
          'detail': 'empty',
          'platform': 'android',
        });
        return;
      }

      await CampaignAttribution.apply(params, source: 'play_install_referrer');

      await AnalyticsService.instance.track(AnalyticsEvent.installAttributed, {
        'label': 'Install Referrer',
        'detail': 'captured',
        'platform': 'android',
        'referrer_click_timestamp_seconds':
            details.referrerClickTimestampSeconds,
        'install_begin_timestamp_seconds':
            details.installBeginTimestampSeconds,
        'google_play_instant': details.googlePlayInstantParam,
        ...params,
      });
    } catch (e, st) {
      debugPrint('[analytics] InstallAttribution failed: $e\n$st');
    }
  }
}
