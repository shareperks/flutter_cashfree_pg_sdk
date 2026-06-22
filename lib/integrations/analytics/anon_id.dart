import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// First-launch UUID kept in [SharedPreferences]. Sent on every analytics
/// event so pre-login and post-login activity can be stitched together
/// server-side via `value.ctx.anon_id`.
///
/// Generated lazily on first read. Never thrown.
class AnonId {
  AnonId._();

  static const _key = 'analytics_anon_id_v1';

  static String? _cached;

  /// Returns the anonymous device id, generating + persisting on first call.
  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final fresh = _uuidV4();
    await prefs.setString(_key, fresh);
    _cached = fresh;
    return fresh;
  }

  /// Clears the in-memory cache. The persisted value is intentionally kept so
  /// the same anon_id survives across logouts (matches the architecture doc).
  static void resetCache() {
    _cached = null;
  }

  static String _uuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // RFC 4122 v4: bits 12-15 of time_hi_and_version = 0b0100
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // bits 6-7 of clock_seq_hi_and_reserved = 0b10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(h).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
