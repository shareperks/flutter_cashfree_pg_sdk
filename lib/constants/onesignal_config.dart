import 'package:flutter/foundation.dart';

/// OneSignal App ID. Override in CI / release with:
/// `--dart-define=ONESIGNAL_APP_ID=...`
class OneSignalConfig {
  OneSignalConfig._();

  static const String appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '1660b763-2ad4-484c-828d-f5c361aa376a',
  );

  /// Verbose SDK logs only in debug builds.
  static bool get enableVerboseLogs => kDebugMode;
}
