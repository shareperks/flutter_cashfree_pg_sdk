import 'package:flutter/foundation.dart';

import 'analytics_context.dart';
import 'analytics_event.dart';
import 'anon_id.dart';
import 'consent_manager.dart';
import 'sinks/analytics_sink.dart';
import 'sinks/debug_sink.dart';
import 'sinks/server_sink.dart';

/// Single public facade for analytics. Screens MUST NOT import vendor SDKs
/// (Firebase, AppsFlyer, CleverTap, ...) directly. They only call:
///
///   AnalyticsService.instance.track(AnalyticsEvent.somethingHappened, {...});
///
/// This guarantees the architecture doc invariant: swapping or adding sinks
/// is a 1-file change.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final List<AnalyticsSink> _sinks = [];
  bool _initialized = false;
  bool _consentGiven = false;

  /// Returns the live consent state for UI (settings screen toggle).
  bool get consentGiven => _consentGiven;

  /// Call once from `main()` BEFORE `runApp`.
  ///
  /// [trackingApiBaseUrl] is the SharePerks data_service origin (no trailing
  /// slash), e.g. `https://listing.shareperks.in`.
  ///
  /// [getAuthToken] reads the JWT from your existing auth store
  /// (`SharedPreferences.getInstance().then((p) => p.getString('token'))`
  /// is fine). Called on every flush so post-login tokens start attaching
  /// automatically.
  Future<void> init({
    required String trackingApiBaseUrl,
    required Future<String?> Function() getAuthToken,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await AnalyticsContext.boot();
    } catch (e) {
      debugPrint('[analytics] context boot failed: $e');
    }

    final server = ServerSink(
      baseUrl: trackingApiBaseUrl,
      getAuthToken: getAuthToken,
    );

    _sinks.addAll([
      if (kDebugMode) DebugSink(),
      server,
    ]);

    for (final s in _sinks) {
      try {
        await s.init();
      } catch (e, st) {
        debugPrint('[analytics] sink ${s.name} init failed: $e\n$st');
      }
    }

    try {
      final anon = await AnonId.get();
      server.setAnonIdHeader(anon);
    } catch (_) {}

    try {
      _consentGiven = await ConsentManager.isGranted();
    } catch (_) {
      _consentGiven = false;
    }
  }

  /// Tell the service the user just granted (or denied) consent.
  void onConsentChanged(bool granted) {
    _consentGiven = granted;
  }

  /// Called after OTP verify / session restore / profile completion.
  /// Forwards to every sink so they can attach the identity to subsequent
  /// events (Firebase setUserId, CleverTap onUserLogin, etc.).
  Future<void> identify(String userId, [Map<String, Object?> props = const {}]) async {
    for (final s in _sinks) {
      try {
        await s.identify(userId, props);
      } catch (_) {}
    }
  }

  /// Set a sticky user property (e.g. `is_demat_linked`, `holdings_value_bucket`).
  Future<void> setUserProperty(String key, Object? value) async {
    for (final s in _sinks) {
      try {
        await s.setUserProperty(key, value);
      } catch (_) {}
    }
  }

  /// Emit a typed event. Drops events tagged `requiresConsent: true` until
  /// consent is granted.
  Future<void> track(
    AnalyticsEvent event, [
    Map<String, Object?> props = const {},
  ]) async {
    if (event.requiresConsent && !_consentGiven) return;
    Map<String, Object?> ctx;
    try {
      ctx = await AnalyticsContext.build();
    } catch (_) {
      ctx = const {};
    }
    for (final s in _sinks) {
      try {
        await s.track(event, props, ctx);
      } catch (_) {}
    }
  }

  /// Emit a screen view. Convenience wrapper.
  Future<void> screen(String name, [Map<String, Object?> props = const {}]) async {
    Map<String, Object?> ctx;
    try {
      ctx = await AnalyticsContext.build();
    } catch (_) {
      ctx = const {};
    }
    for (final s in _sinks) {
      try {
        await s.screen(name, props, ctx);
      } catch (_) {}
    }
  }

  /// Best-effort flush — call from `AppLifecycleState.paused` to maximise
  /// chance of delivery before the OS suspends us.
  Future<void> flush() async {
    for (final s in _sinks) {
      if (s is ServerSink) {
        try {
          await s.flush();
        } catch (_) {}
      }
    }
  }

  /// Called on logout. Lets every sink clear cached identity and flush
  /// pending events under the old user before they get re-attributed.
  Future<void> reset() async {
    for (final s in _sinks) {
      try {
        await s.reset();
      } catch (_) {}
    }
  }
}
