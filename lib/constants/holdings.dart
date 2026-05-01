/// Typed paths for assets bundled with the [holdings] package.
///
/// Paths use Flutter’s `packages/<package>/...` form so they resolve when the
/// plugin is used from an app **without** passing [Image.asset] `package:`.
///
/// ```dart
/// Image.asset(HoldingsAssets.brokers.zerodha);
/// // or
/// for (final broker in HoldingsBrokerAssets.all) {
///   Image.asset(broker.imageAssetPath);
/// }
/// ```
abstract final class HoldingsAssets {
  HoldingsAssets._();

  /// [Image.asset] `package` parameter when using **short** paths (`assets/...`).
  static const String packageName = 'holdings';

  /// Root prefix for assets in this package (`assets`).
  static const String root = 'assets';

  /// Logos under `assets/brokers/`.
  static const HoldingsBrokerAssets brokers = HoldingsBrokerAssets._();
}

/// Display name, stable [brokerKey] for APIs, bundled logo path, and product flags.
final class HoldingBroker {
  const HoldingBroker({
    required this.name,
    required this.brokerKey,
    required this.imageAssetPath,
    this.supportsOrderPlacement = false,
    this.supportsHoldingsImport = false,
    this.supportsAccountOpening = false,
    this.supportsSmallcase = false,
  });

  /// Human-readable broker name (for UI labels).
  final String name;

  /// Stable broker identifier for routing, analytics, and callbacks (e.g. `kite`, `icici`).
  final String brokerKey;

  /// Full bundle key for [Image.asset] (same strings as [HoldingsBrokerAssets] getters).
  final String imageAssetPath;

  final bool supportsOrderPlacement;

  /// Product flag (e.g. holdings import availability).
  final bool supportsHoldingsImport;

  final bool supportsAccountOpening;

  /// Whether smallcase is enabled for this broker in the product matrix.
  final bool supportsSmallcase;
}

/// Paths for broker images (full bundle keys for this package).
final class HoldingsBrokerAssets {
  const HoldingsBrokerAssets._();

  static const String _fivePaisa = 'assets/brokers/5paisa.png';
  static const String _aliceBlue = 'assets/brokers/aliceblue.png';
  static const String _angelOne = 'assets/brokers/angelOne.png';
  static const String _axisSecurities = 'assets/brokers/axisSecurities.png';
  static const String _dhan = 'assets/brokers/dhan.png';
  static const String _fisdom = 'assets/brokers/fisdom.png';
  static const String _fundzBazar = 'assets/brokers/fundzBazar.png';
  static const String _growwAppIconHd = 'assets/brokers/groww-app-icon-hd.webp';
  static const String _hdfcSecurities = 'assets/brokers/HDFCSecurities.jpg';
  static const String _iciciDirect = 'assets/brokers/ICICIdirect.jpg';
  static const String _iifl = 'assets/brokers/IIFL.png';
  static const String _kotakSecurities = 'assets/brokers/KotakSecurities.png';
  static const String _motilalOswal = 'assets/brokers/MotilalOswal.png';
  static const String _numava = 'assets/brokers/Numava.png';
  static const String _paytm = 'assets/brokers/paytm.png';
  static const String _sbiSecurities = 'assets/brokers/SBISecurities.png';
  static const String _trustline = 'assets/brokers/Trustline.png';
  static const String _upstox = 'assets/brokers/Upstox.png';
  static const String _zerodha = 'assets/brokers/Zerodha.png';

  /// Every broker with [HoldingBroker.name], [HoldingBroker.brokerKey], and feature flags.
  static const List<HoldingBroker> all = [
    HoldingBroker(
      name: '5paisa',
      brokerKey: 'fivepaisa',
      imageAssetPath: _fivePaisa,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Alice Blue',
      brokerKey: 'aliceblue',
      imageAssetPath: _aliceBlue,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'Angel One',
      brokerKey: 'angelbroking',
      imageAssetPath: _angelOne,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Axis Securities',
      brokerKey: 'axis',
      imageAssetPath: _axisSecurities,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'Dhan',
      brokerKey: 'dhan',
      imageAssetPath: _dhan,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Fisdom',
      brokerKey: 'fisdom',
      imageAssetPath: _fisdom,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'FundzBazar',
      brokerKey: 'fundzbazar',
      imageAssetPath: _fundzBazar,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'Groww',
      brokerKey: 'groww',
      imageAssetPath: _growwAppIconHd,
    ),
    HoldingBroker(
      name: 'HDFC Securities',
      brokerKey: 'hdfc',
      imageAssetPath: _hdfcSecurities,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'ICICI Direct',
      brokerKey: 'icici',
      imageAssetPath: _iciciDirect,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'IIFL',
      brokerKey: 'iifl',
      imageAssetPath: _iifl,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Kotak Securities',
      brokerKey: 'kotak',
      imageAssetPath: _kotakSecurities,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'Motilal Oswal',
      brokerKey: 'motilal',
      imageAssetPath: _motilalOswal,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Numava',
      brokerKey: 'edelweiss',
      imageAssetPath: _numava,
    ),
    HoldingBroker(
      name: 'Paytm Money',
      brokerKey: 'paytm',
      imageAssetPath: _paytm,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'SBI Securities',
      brokerKey: 'sbi',
      imageAssetPath: _sbiSecurities,
      supportsOrderPlacement: true,
    ),
    HoldingBroker(
      name: 'Trustline',
      brokerKey: 'trustline',
      imageAssetPath: _trustline,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Upstox',
      brokerKey: 'upstox',
      imageAssetPath: _upstox,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsSmallcase: true,
    ),
    HoldingBroker(
      name: 'Zerodha',
      brokerKey: 'kite',
      imageAssetPath: _zerodha,
      supportsOrderPlacement: true,
      supportsHoldingsImport: true,
      supportsAccountOpening: true,
      supportsSmallcase: true,
    ),
  ];

  String get fivePaisa => _fivePaisa;
  String get aliceBlue => _aliceBlue;
  String get angelOne => _angelOne;
  String get axisSecurities => _axisSecurities;
  String get dhan => _dhan;
  String get fisdom => _fisdom;
  String get fundzBazar => _fundzBazar;
  String get growwAppIconHd => _growwAppIconHd;
  String get hdfcSecurities => _hdfcSecurities;
  String get iciciDirect => _iciciDirect;
  String get iifl => _iifl;
  String get kotakSecurities => _kotakSecurities;
  String get motilalOswal => _motilalOswal;
  String get numava => _numava;
  String get paytm => _paytm;
  String get sbiSecurities => _sbiSecurities;
  String get trustline => _trustline;
  String get upstox => _upstox;
  String get zerodha => _zerodha;
}
