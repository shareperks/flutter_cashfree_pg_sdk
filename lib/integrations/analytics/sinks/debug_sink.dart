import 'package:flutter/foundation.dart';

import '../analytics_event.dart';
import 'analytics_sink.dart';

/// Pretty-prints every event to the console. Only added to the sink list in
/// `kDebugMode` so it never runs in release builds.
class DebugSink implements AnalyticsSink {
  @override
  String get name => 'debug';

  @override
  Future<void> init() async {
    if (!kDebugMode) return;
    debugPrint('[analytics] DebugSink ready');
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> props) async {
    if (!kDebugMode) return;
    debugPrint('[analytics] identify user=$userId props=$props');
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    if (!kDebugMode) return;
    debugPrint('[analytics] user_property $key=$value');
  }

  @override
  Future<void> track(
    AnalyticsEvent event,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    if (!kDebugMode) return;
    debugPrint('[analytics] ${event.category}/${event.name} '
        'props=$props ctx=${_short(ctx)}');
  }

  @override
  Future<void> screen(
    String screenName,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    if (!kDebugMode) return;
    debugPrint('[analytics] screen=$screenName props=$props');
  }

  @override
  Future<void> reset() async {
    if (!kDebugMode) return;
    debugPrint('[analytics] reset');
  }

  @override
  Future<void> onConsentChanged(bool granted) async {
    if (!kDebugMode) return;
    debugPrint('[analytics] consent=${granted ? 'granted' : 'denied'}');
  }

  Map<String, Object?> _short(Map<String, Object?> ctx) {
    return {
      'anon_id': ctx['anon_id'],
      'session_id': ctx['session_id'],
      'platform': ctx['platform'],
      'app_version': ctx['app_version'],
    };
  }
}
