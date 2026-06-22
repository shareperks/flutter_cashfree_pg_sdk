import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Bottom sheet after verifying perk eligibility.
void eligibilitySheet(BuildContext context, bool isEligible, String rewardId) {
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
      final imageAsset = isEligible
          ? Assets.ASSETS_CARDS_ELIGIBLEREWARD_PNG
          : Assets.ASSETS_CARDS_NOTELIGIBLEREWARD_PNG;

      return Padding(
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
                    },
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isEligible
                      ? SharePerksColors.accent
                      : SharePerksColors.primary,
                ),
                child: Text(
                  isEligible ? 'Proceed' : 'Claim Non-Shareholder Perk',
                ),
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
  );
}

/// Shown when the user has no demat / broker linked (cannot verify holdings).
void noDematAccountConnectSheet(BuildContext context) {
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
  );
}
