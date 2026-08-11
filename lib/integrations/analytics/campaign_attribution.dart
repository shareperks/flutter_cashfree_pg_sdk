import 'package:shared_preferences/shared_preferences.dart';

/// Persists last-touch Google Ads / campaign UTM parameters and merges them
/// into every analytics event via [AnalyticsContext].
class CampaignAttribution {
  CampaignAttribution._();

  static const _prefsKey = 'analytics_campaign_attribution_v1';

  static const utmKeys = [
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'gclid',
    'gbraid',
    'wbraid',
    'campaign_id',
    'adgroup_id',
    'creative_id',
  ];

  static Map<String, String> _cached = {};
  static bool _loaded = false;

  static Map<String, String> get current => Map.unmodifiable(_cached);

  static Future<void> boot() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey);
      if (raw == null) return;
      for (final entry in raw) {
        final i = entry.indexOf('=');
        if (i <= 0) continue;
        _cached[entry.substring(0, i)] = entry.substring(i + 1);
      }
    } catch (_) {}
  }

  /// Parses UTM / Google click ids from a URI or raw referrer query string.
  static Map<String, String> parseFromUri(Uri uri) {
    final out = <String, String>{};
    for (final key in utmKeys) {
      final v = uri.queryParameters[key];
      if (v != null && v.isNotEmpty) out[key] = v;
    }
    return out;
  }

  /// Play Install Referrer returns a query-string like
  /// `utm_source=google-play&utm_medium=organic` or Ads click params.
  static Map<String, String> parseFromReferrerString(String referrer) {
    try {
      final uri = Uri.splitQueryString(referrer);
      final out = <String, String>{};
      for (final key in utmKeys) {
        final v = uri[key];
        if (v != null && v.isNotEmpty) out[key] = v;
      }
      // Also keep common Play keys.
      for (final key in ['utm_source', 'utm_medium', 'utm_campaign', 'referrer']) {
        final v = uri[key];
        if (v != null && v.isNotEmpty) out.putIfAbsent(key, () => v);
      }
      if (out.isEmpty && referrer.isNotEmpty) {
        out['install_referrer_raw'] = referrer.length > 100
            ? referrer.substring(0, 100)
            : referrer;
      }
      return out;
    } catch (_) {
      return referrer.isEmpty
          ? {}
          : {
              'install_referrer_raw': referrer.length > 100
                  ? referrer.substring(0, 100)
                  : referrer,
            };
    }
  }

  /// Last-touch update: overwrites existing keys when new values arrive.
  static Future<void> apply(Map<String, String> params, {String? source}) async {
    if (params.isEmpty) return;
    await boot();
    _cached = {..._cached, ...params};
    if (source != null && source.isNotEmpty) {
      _cached['attribution_source'] = source;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        _cached.entries.map((e) => '${e.key}=${e.value}').toList(),
      );
    } catch (_) {}
  }

  /// Props to attach on every event / Firebase default params.
  static Map<String, Object?> asEventProps() {
    if (_cached.isEmpty) return const {};
    return Map<String, Object?>.from(_cached);
  }
}
