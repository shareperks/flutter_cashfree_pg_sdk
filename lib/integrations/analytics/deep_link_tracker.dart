import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';
import 'campaign_attribution.dart';
import 'journey_context.dart';

/// Handles direct + deferred-style deep links for Google Analytics.
///
/// - Cold/warm links via `app_links`
/// - UTM / gclid extracted into [CampaignAttribution]
/// - Emits [AnalyticsEvent.deeplinkOpened]
///
/// Deferred deep links from Google Ads on Android arrive through Play Install
/// Referrer ([InstallAttribution]); this class covers open-time deep links
/// (`shareperks://…`, `https://shareperks.in/…`).
class DeepLinkTracker {
  DeepLinkTracker._();
  static final DeepLinkTracker instance = DeepLinkTracker._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial, isDeferred: false, isInitial: true);
      }
    } catch (e) {
      debugPrint('[analytics] DeepLinkTracker initial failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri, isDeferred: false, isInitial: false)),
      onError: (Object e) {
        debugPrint('[analytics] DeepLinkTracker stream error: $e');
      },
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  Future<void> _handle(
    Uri uri, {
    required bool isDeferred,
    required bool isInitial,
  }) async {
    try {
      final utm = CampaignAttribution.parseFromUri(uri);
      if (utm.isNotEmpty) {
        await CampaignAttribution.apply(
          utm,
          source: isDeferred ? 'deferred_deeplink' : 'deeplink',
        );
      }

      JourneyContext.currentScreen ??= uri.path.isEmpty ? '/' : uri.path;

      await AnalyticsService.instance.track(AnalyticsEvent.deeplinkOpened, {
        'label': 'Deep Link Opened',
        'url': uri.toString().length > 100
            ? uri.toString().substring(0, 100)
            : uri.toString(),
        'path': uri.path,
        'host': uri.host,
        'scheme': uri.scheme,
        'is_initial': isInitial,
        'is_deferred': isDeferred,
        ...utm,
      });
    } catch (e, st) {
      debugPrint('[analytics] DeepLinkTracker handle failed: $e\n$st');
    }
  }
}
