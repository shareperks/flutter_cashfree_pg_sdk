import '../analytics_event.dart';

/// Common interface for every analytics destination (Firebase, Sentry,
/// AppsFlyer, CleverTap, our own /track API, debug printer, ...).
///
/// Implementations MUST be best-effort: never throw out of any method.
/// A broken sink must never crash the app.
abstract class AnalyticsSink {
  String get name;

  /// Called once at app startup. Use to set up SDKs, restore queues, etc.
  Future<void> init();

  /// Called when the app learns who the user is (after OTP verify / session
  /// restore). [props] carries the identity fields (`user_id`, hashed PII,
  /// signup_date, etc.).
  Future<void> identify(String userId, Map<String, Object?> props);

  /// Set a sticky user property (`is_demat_linked`, `linked_brokers_count`,
  /// `holdings_value_bucket`, ...). Cheap to call repeatedly; sinks dedupe.
  Future<void> setUserProperty(String key, Object? value);

  /// Emit a typed event with structured props. The sink receives the already-
  /// enriched `ctx` (anon_id, app_version, platform, ...) in [ctx] so it can
  /// forward verbatim or remap to its own SDK shape.
  Future<void> track(
    AnalyticsEvent event,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  );

  /// Logical screen view. Same payload shape as [track], pre-routed to the
  /// sink's screen-view API where one exists; otherwise treated as a regular
  /// `screen_view` event.
  Future<void> screen(
    String screenName,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  );

  /// Called on logout — clear cached identity, flush pending queues.
  Future<void> reset();
}
