import 'package:shared_preferences/shared_preferences.dart';

enum ConsentState { unknown, granted, denied }

/// Reads / writes the user's analytics consent flag in [SharedPreferences].
/// Events tagged `requiresConsent: true` in [AnalyticsEvent] are dropped
/// until the user grants consent.
///
/// Non-PII safety-critical events (crash reports, payment receipts, security)
/// stay unflagged so they always fire.
class ConsentManager {
  ConsentManager._();

  static const _key = 'analytics_consent_v1';

  /// Returns true if the user has granted consent.
  static Future<bool> isGranted() async {
    final state = await read();
    return state == ConsentState.granted;
  }

  static Future<ConsentState> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    switch (raw) {
      case 'granted':
        return ConsentState.granted;
      case 'denied':
        return ConsentState.denied;
      default:
        return ConsentState.unknown;
    }
  }

  static Future<void> grant() => _write(ConsentState.granted);
  static Future<void> deny() => _write(ConsentState.denied);
  static Future<void> reset() => _write(ConsentState.unknown);

  static Future<void> _write(ConsentState state) async {
    final prefs = await SharedPreferences.getInstance();
    switch (state) {
      case ConsentState.granted:
        await prefs.setString(_key, 'granted');
        break;
      case ConsentState.denied:
        await prefs.setString(_key, 'denied');
        break;
      case ConsentState.unknown:
        await prefs.remove(_key);
        break;
    }
  }
}
