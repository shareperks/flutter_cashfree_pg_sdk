import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/EligibleRewardCard.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/screens/rewards/utils/reward_eligibility.dart';

/// Bottom sheet after verifying perk eligibility.
void eligibilitySheet(
  BuildContext context, {
  required bool isEligible,
  bool isBrokerageEligible = false,
  required String rewardId,
  num? shareholderRate,
  num? brokerageRate,
  num? nonShareholderRate,
  bool listedOnExchange = true,
  bool reqReimport = false,
  String? rewardType,
}) {
  final tier = resolveRewardTier(
    isEligible: isEligible,
    isBrokerageEligible: isBrokerageEligible,
    reqReimport: reqReimport,
  );
  final restoreScreen = trackBottomSheet('eligibility_result_sheet', {
    'is_eligible': isEligible,
    'is_brokerage_eligible': isBrokerageEligible,
    'eligibility_tier': tier.name,
  });
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
      final imageAsset = tier == RewardEligibilityTier.nonHolder
          ? Assets.ASSETS_CARDS_NOTELIGIBLEREWARD_PNG
          : Assets.ASSETS_CARDS_ELIGIBLEREWARD_PNG;

      final proceedLabel = switch (tier) {
        RewardEligibilityTier.fullyEligible =>
          listedOnExchange ? 'Claim Shareholder Perk' : 'Claim Brokerage Perk',
        RewardEligibilityTier.brokerageEligible => 'Claim Brokerage Perk',
        RewardEligibilityTier.nonHolder => 'Claim Standard Reward',
      };

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                imageAsset,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              RewardRatesSection(
                shareholderRate: shareholderRate,
                brokerageRate: brokerageRate,
                nonShareholderRate: nonShareholderRate,
                isEligible: isEligible,
                isBrokerageEligible: isBrokerageEligible,
                listedOnExchange: listedOnExchange,
                reqReimport: reqReimport,
                rewardType: rewardType,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.pushNamed(
                      RouteNames.GIFTCARD_AMOUNT_SCREEN,
                      extra: {
                        "rewardId": rewardId,
                        "isEligible": isEligible.toString(),
                        "isBrokerageEligible": isBrokerageEligible.toString(),
                        // Only force standard rate when neither higher tier applies.
                        "forceNonHolder":
                            (tier == RewardEligibilityTier.nonHolder)
                                .toString(),
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tier == RewardEligibilityTier.fullyEligible
                        ? SharePerksColors.accent
                        : SharePerksColors.primary,
                  ),
                  child: Text(proceedLabel),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(restoreScreen);
}

/// Shown when the user has no demat / broker linked (cannot verify holdings).
void noDematAccountConnectSheet(BuildContext context) {
  final restoreScreen = trackBottomSheet('no_demat_connected_sheet');
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'No demat account connected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 20,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import your holdings to verify eligibility and unlock shareholder perks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 14,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.pushNamed(RouteNames.LIST_BROKER_VIEW_SCREEN);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: SharePerksColors.primary,
                ),
                child: const Text('Import Holdings'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(restoreScreen);
}
