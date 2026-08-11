import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'anon_id.dart';
import 'campaign_attribution.dart';
import 'session_id.dart';

/// Per-event context attached to every analytics payload. Server stores it as
/// `value.ctx` so we can slice by app_version, platform, network, etc.
///
/// Captured once at startup ([AnalyticsContext.boot]) and reused. Network is
/// re-read on every event because it changes frequently.
class AnalyticsContext {
  AnalyticsContext._();

  static String? _appVersion;
  static String? _buildNumber;
  static String? _platform;
  static String? _locale;

  /// Call once from [AnalyticsService.init].
  static Future<void> boot() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (_) {}

    try {
      if (Platform.isAndroid) {
        _platform = 'android';
      } else if (Platform.isIOS) {
        _platform = 'ios';
      } else {
        _platform = 'web';
      }
    } catch (_) {
      _platform = 'web';
    }

    try {
      _locale = Platform.localeName;
    } catch (_) {}

    await CampaignAttribution.boot();
  }

  /// Returns the `ctx` object to attach to every event.
  /// Reads network on every call; everything else is cached.
  static Future<Map<String, Object?>> build() async {
    final anon = await AnonId.get();
    final network = await _readNetwork();

    final ctx = <String, Object?>{
      'anon_id': anon,
      'session_id': SessionId.value,
      'ts_client_ms': DateTime.now().millisecondsSinceEpoch,
      ...CampaignAttribution.asEventProps(),
    };
    if (_appVersion != null) ctx['app_version'] = _appVersion;
    if (_buildNumber != null) ctx['build_number'] = _buildNumber;
    if (_platform != null) ctx['platform'] = _platform;
    if (_locale != null) ctx['locale'] = _locale;
    ctx['network'] = network;
    return ctx;
  }

  static Future<String> _readNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return 'unknown';
      final first = results.first;
      if (results.every((r) => r == ConnectivityResult.none)) return 'none';
      if (first == ConnectivityResult.wifi || first == ConnectivityResult.ethernet) {
        return 'wifi';
      }
      if (first == ConnectivityResult.mobile) return 'mobile';
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
