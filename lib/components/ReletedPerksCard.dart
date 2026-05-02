import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';

class RelatedPerksCard extends StatelessWidget {
  final String title;
  final List<RewardItem> items;
  const RelatedPerksCard({super.key, required this.items, required this.title});

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      width: double.infinity,
      borderWidth: 1,
      color: SharePerksColors.accent.withValues(alpha: 0.3),
      borderRadius: SharePerksRadii.lg,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 10),
            child: TitleView(
              title: SizedBox(
                width: MediaQuery.of(context).size.width / 1.8,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SharePerksColors.accent,
                    fontSize: 18,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: GestureDetector(
                onTap: () {
                  context.pushNamed(RouteNames.CATEGORY_SCREEN);
                },
                child: LabelWithForwardIcon(
                  iconColor: SharePerksColors.accent,
                  iconSize: 18,

                  label: Text(
                    'View all',
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 6),
                  ...List.generate(items.length, (index) {
                    RewardItem reward = items[index];
                    return RewardCard(
                      rewardId: reward.id!,
                      type: reward.type!,
                      typeName: reward.type,
                      title: reward.title ?? "--",
                      imageUrl: imageUrl(reward.image ?? ""),
                      isEligible: reward.isEligible ?? false,
                      eligibility: reward.companyName ?? "--",
                    );
                  }),
                  SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
