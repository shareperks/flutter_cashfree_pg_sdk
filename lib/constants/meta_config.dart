/// Meta (Facebook) App Events credentials. Override in CI / release with:
/// `--dart-define=META_APP_ID=... --dart-define=META_CLIENT_TOKEN=...`
class MetaConfig {
  MetaConfig._();

  static const String appId = String.fromEnvironment(
    'META_APP_ID',
    defaultValue: '1558786092457844',
  );

  static const String clientToken = String.fromEnvironment(
    'META_CLIENT_TOKEN',
    defaultValue: '2648bf4715f176d02dcbf821f682e558',
  );

  static const String displayName = 'SharePerks';

  /// Facebook URL scheme used by the native SDK (`fb` + App ID).
  static String get loginProtocolScheme => 'fb$appId';
}
