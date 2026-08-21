import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/consent_manager.dart';
import 'package:shareperks/integrations/analytics/deep_link_tracker.dart';
import 'package:shareperks/integrations/analytics/install_attribution.dart';
import 'package:shareperks/integrations/att_service.dart';
import 'package:shareperks/repository/host.dart';

const _firstOpenKey = 'analytics_first_open_seen_v1';

bool _bootstrapped = false;

/// Waits for the ATT decision (iOS), then starts analytics / advertising SDKs.
///
/// Safe to call more than once. Must run after [LocalStorage.init] and
/// [Firebase.initializeApp]. First-party SharePerks still works if ATT is
/// denied or restricted.
Future<void> bootstrapTracking() async {
  if (_bootstrapped) return;
  _bootstrapped = true;

  try {
    final att = await AttService.instance.ensureRequested();
    debugPrint('[att] bootstrap continuing status=$att');

    if (await ConsentManager.read() == ConsentState.unknown) {
      await ConsentManager.grant();
    }

    await AnalyticsService.instance.init(
      trackingApiBaseUrl: Host.listingUrl,
      getAuthToken: () async => LocalStorage.getToken(),
    );
    await AnalyticsService.instance.onConsentChanged(
      await ConsentManager.isGranted(),
    );
    await AnalyticsService.instance.onTrackingAuthorizationChanged(
      AttService.instance.allowsAdvertisingTracking,
    );

    unawaited(InstallAttribution.captureOnce());
    unawaited(DeepLinkTracker.instance.start());

    final seenFirstOpen = LocalStorage.getString(_firstOpenKey) == '1';
    if (!seenFirstOpen) {
      await LocalStorage.setString(_firstOpenKey, '1');
    }
    unawaited(
      AnalyticsService.instance.track(AnalyticsEvent.appOpened, {
        'is_first_open': !seenFirstOpen,
        'att_status': att.name,
      }),
    );
  } catch (e, st) {
    debugPrint('[att] bootstrapTracking failed: $e\n$st');
  }
}
