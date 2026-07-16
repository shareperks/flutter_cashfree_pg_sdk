import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/journey_context.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:soui/elements/ImageBuilder.dart';

Map<String, String> typeNameMap = {
  'OFFER': 'Discount Coupon',
  'CREDIT': 'Gift Card',
  'BENEFIT': 'Cashback',
};

class RewardCard extends StatelessWidget {
  final bool isEligible;
  final String imageUrl;
  final String title;
  final String rewardId;
  final String eligibility;
  final VoidCallback? onTap;
  final double width;
  final String type;
  final String? typeName;
  final bool isNew;

  // OFFER, CREDIT, BENEFIT
  const RewardCard({
    super.key,
    this.isEligible = false,
    this.width = 165,
    this.imageUrl = '',
    this.title = '',
    required this.rewardId,
    this.eligibility = '',
    this.onTap,
    required this.type,
    this.typeName,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,

      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEligible
              ? SharePerksColors.accent.withValues(alpha: 0.3)
              : SharePerksColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Stack(
              children: [
                ImageBuilder(
                  imageUrl: imageUrl,
                  width: width,
                  height: 121,
                  fit: BoxFit.cover,
                ),
                if (isEligible)
                  Positioned(
                    top: -1,
                    left: 0,
                    child: SvgPicture.asset(
                      Assets.ASSETS_ICONS_ELIGIBLEREWARD_SVG,
                    ),
                  ),
                if (isNew)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: SvgPicture.asset(
                      Assets.ASSETS_ICONS_NEWADDITIONS_SVG,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ).copyWith(top: 0, bottom: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                SizedBox(
                  height: 43,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,

                      color: SharePerksColors.textPrimaryLight,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Eligible via ",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SharePerksColors.textSecondaryLight,
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        (eligibility),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: SharePerksColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              4,
            ).copyWith(top: 0).copyWith(bottom: 6),
            child: Center(
              child: GestureDetector(
                onTap:
                    onTap ??
                    () {
                      navigateRewardScreen(
                        type,
                        rewardId,
                        source: 'home',
                      );
                    },
                child: Container(
                  width: width - 16,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isEligible
                        ? SharePerksColors.accent
                        : SharePerksColors.borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEligible
                          ? SharePerksColors.accent
                          : SharePerksColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "View ${typeNameMap[typeName ?? ''] ?? typeName ?? ''}",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isEligible
                            ? SharePerksColors.backgroundLight
                            : SharePerksColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String perkTypeFromRewardType(String type) {
  switch (type) {
    case 'CREDIT':
      return 'giftcard';
    case 'BENEFIT':
      return 'cashback';
    case 'OFFER':
      return 'promocode';
    default:
      return type.toLowerCase();
  }
}

void navigateRewardScreen(
  String type,
  String rewardId, {
  String source = 'unknown',
  int? position,
  String? brandId,
  String? redirectKind,
}) {
  final perkType = perkTypeFromRewardType(type);
  JourneyContext.startJourney(rewardId: rewardId, perkType: perkType);
  trackAction(AnalyticsEvent.perkCardClicked, {
    'reward_id': rewardId,
    'perk_type': perkType,
    'source': source,
    if (position != null) 'position': position,
    if (brandId != null) 'brand_id': brandId,
    if (redirectKind != null) 'redirect_kind': redirectKind,
  });

  if (type == "CREDIT") {
    GoRouterKey.currentContext?.pushNamed(
      RouteNames.GIFTCARD_VIEW_SCREEN,
      extra: {"rewardId": rewardId},
    );
  }
  if (type == "BENEFIT") {
    GoRouterKey.currentContext?.pushNamed(
      RouteNames.CASHBACK_VIEW_SCREEN,
      extra: {"rewardId": rewardId},
    );
  }
  if (type == "OFFER") {
    GoRouterKey.currentContext?.pushNamed(
      RouteNames.PROMOCODE_VIEW_SCREEN,
      extra: {"rewardId": rewardId},
    );
  }
}
