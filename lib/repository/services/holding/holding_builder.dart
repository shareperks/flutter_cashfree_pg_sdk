import 'package:flutter/material.dart';
import 'package:shareperks/constants/holdings.dart';
import 'package:shareperks/repository/services/holding/holding_model.dart';

/// One connected broker account row for account-switcher UIs.
class HoldingSelectItem {
  const HoldingSelectItem({
    required this.id,
    required this.label,
    required this.leading,
    required this.holding,
  });

  /// Snapshot / account id from the API.
  final String id;

  final String label;

  final Widget leading;

  final FetchUserHoldingsResponse holding;
}

/// Maps [FetchUserHoldingsResponse] list into [HoldingSelectItem]s for dropdowns / menus.
class HoldingSelectBuilder {
  HoldingSelectBuilder._();

  static List<HoldingSelectItem> build(
    List<FetchUserHoldingsResponse> holdings,
  ) {
    return [
      for (final h in holdings)
        HoldingSelectItem(
          id: h.id,
          label: '${_brokerFor(h.brokerCode).name}',
          leading: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(100),
            child: Image.asset(
              _brokerFor(h.brokerCode).imageAssetPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_balance, size: 18),
            ),
          ),
          holding: h,
        ),
    ];
  }

  static HoldingBroker _brokerFor(String brokerCode) {
    for (final b in HoldingsBrokerAssets.all) {
      if (b.brokerKey == brokerCode) return b;
    }
    final fallback = HoldingsBrokerAssets.all.first;
    return HoldingBroker(
      name: brokerCode,
      brokerKey: brokerCode,
      imageAssetPath: fallback.imageAssetPath,
    );
  }
}
