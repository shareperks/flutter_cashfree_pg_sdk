import 'package:flutter/material.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';
import 'package:soui/elements/key_value_list.dart';
import 'package:soui/elements/title_view.dart';

class PerkBasicInfo extends StatelessWidget {
  const PerkBasicInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      padding: EdgeInsets.all(10),
      borderRadius: 16,
      borderWidth: 1,
      color: SharePerksColors.primary.withAlpha(15),
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageBuilder(
            imageUrl:
                "https://www.youngurbanproject.com/wp-content/uploads/2025/05/Zomato-Case-Study.jpg",
            width: MediaQuery.of(context).size.width,
            borderRadius: 14,
            alignment: Alignment.bottomLeft,
            aspectRatio: 2.65,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                PerkInfoBar(type: "Credit"),
                Text(
                  'Reward Title on the given brand ',
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 20,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                KeyValueList(
                  keyWidget: Text(
                    'Ticker',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  valueWidget: Text(
                    'Eternal Ltd.',
                    style: TextStyle(
                      color: const Color(0xFF5182FE) /* Information */,
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF5182FE),
                    ),
                  ),
                ),
                KeyValueList(
                  keyWidget: Text(
                    'Perk ID',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  valueWidget: Text(
                    'ZOM023',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),

                CollapseCard(
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, top: 4),
                    child: Text(
                      'Perk Details',
                      style: TextStyle(
                        color: SharePerksColors.accent,
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  color: SharePerksColors.accent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: 1,
                        color: SharePerksColors.accent,
                      ),
                    ),
                    child: Text(
                      "1.3 Gain: A measurement of how much light the screen reflects. Higher gain (like 1.3) is better for environments with some ambient light or for increasing the brightness of a 4K/HDR projector.",
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                EligibilityCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PerkInfoBar extends StatelessWidget {
  final String type;
  const PerkInfoBar({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'PERK DETAILS',
          style: TextStyle(
            color: const Color(0xFF5C0191),
            fontSize: 10,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: const Color(0xFF6400E0)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: const Color(0xFF6400E0),
              fontSize: 10,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w700,
              height: 1.40,
            ),
          ),
        ),
      ],
    );
  }
}

class PerkTerms extends StatelessWidget {
  const PerkTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        TitleView(
          title: Text(
            'Important Terms & Conditions',
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 14,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: LabelWithForwardIcon(
            iconSize: 18,
            iconColor: SharePerksColors.textSecondaryLight,
            label: Text(
              'View all',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: SharePerksColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 150,
                child: Text(
                  'Lorem ipsum dolor sit amet consectetur. Ut pretium nisi aenean diam tincidunt eu. Nam quis massa volutpat turpis nisl nec arcu.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF898989),
                    fontSize: 11,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Image.asset(Assets.ASSETS_ICONS_NOTE_PNG, width: 48),
            ],
          ),
        ),
      ],
    );
  }
}
