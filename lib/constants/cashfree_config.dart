import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

/// Cashfree PG environment. Uses sandbox in debug builds.
class CashfreeConfig {
  CashfreeConfig._();

  static CFEnvironment get environment =>
      kDebugMode ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION;
}
