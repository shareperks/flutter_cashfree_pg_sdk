import 'package:flutter/material.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';
import 'package:soui/elements/key_value_list.dart';
import 'package:soui/elements/title_view.dart';

class PerkBasicInfoData {
  final String imageUrl;
  final String typeLabel;
  final String title;
  final String tickerLabel;
  final String tickerValue;
  final bool underlineTicker;
  final String perkIdLabel;
  final String perkIdValue;
  final String detailsTitle;
  final String? detailsBody;
  final EligibilityCardsData? eligibility;

  const PerkBasicInfoData({
    required this.imageUrl,
    required this.typeLabel,
    required this.title,
    this.tickerLabel = "Ticker",
    required this.tickerValue,
    this.underlineTicker = true,
    this.perkIdLabel = "Perk ID",
    required this.perkIdValue,
    this.detailsTitle = 'Perk Details',
    required this.detailsBody,
    this.eligibility,
  });

  static const PerkBasicInfoData placeholder = PerkBasicInfoData(
    imageUrl: '',
    typeLabel: 'Credit',
    title: 'Reward Title on the given brand',
    tickerLabel: 'Ticker',
    tickerValue: 'Eternal Ltd.',
    perkIdLabel: 'Perk ID',
    perkIdValue: 'ZOM023',
    detailsBody: 'Loading perk details…',
    eligibility: EligibilityCardsData.placeholder,
  );
}

class PerkBasicInfo extends StatelessWidget {
  const PerkBasicInfo({
    super.key,
    this.data = PerkBasicInfoData.placeholder,
    this.onTickerTap,
  });

  final PerkBasicInfoData data;
  final VoidCallback? onTickerTap;

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
            imageUrl: imageUrl(data.imageUrl),
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
                PerkInfoBar(type: data.typeLabel),
                Text(
                  data.title,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 20,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                KeyValueList(
                  keyWidget: Text(
                    data.tickerLabel,
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  valueWidget: InkWell(
                    onTap: onTickerTap,
                    child: Text(
                      data.tickerValue,
                      style: TextStyle(
                        color: const Color(0xFF5182FE) /* Information */,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        decoration: data.underlineTicker
                            ? TextDecoration.underline
                            : null,
                        decorationColor: const Color(0xFF5182FE),
                      ),
                    ),
                  ),
                ),
                KeyValueList(
                  keyWidget: Text(
                    data.perkIdLabel,
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  valueWidget: Text(
                    data.perkIdValue,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),

                Builder(
                  builder: (context) {
                    if (data.detailsBody == null) {
                      return SizedBox();
                    }
                    return CollapseCard(
                      title: Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, top: 4),
                        child: Text(
                          data.detailsTitle,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            width: 1,
                            color: SharePerksColors.accent,
                          ),
                        ),
                        child: Text(
                          data.detailsBody ?? "",
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 5),
                if (data.eligibility != null)
                  EligibilityCards(data: data.eligibility!),
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
  const PerkTerms({
    super.key,
    required this.termsAndConditions,
    this.title = 'Important Terms & Conditions',
    this.viewAllLabel = 'View all',
    this.onViewAll,
  });

  final String title;
  final String viewAllLabel;
  final String termsAndConditions;
  final VoidCallback? onViewAll;

  void _defaultViewAll(BuildContext context, {VoidCallback? onViewAll}) {
    final text = termsAndConditions.trim();
    if (text.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 16,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (onViewAll != null)
                  Center(
                    child: TextButton(
                      onPressed: onViewAll,
                      child: Text("Read More"),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = termsAndConditions.trim().isEmpty
        ? 'Terms will appear here.'
        : termsAndConditions.trim();

    return Column(
      spacing: 8,
      children: [
        TitleView(
          title: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 14,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: InkWell(
            onTap: termsAndConditions.trim().isEmpty
                ? null
                : () => _defaultViewAll(context, onViewAll: onViewAll),
            child: LabelWithForwardIcon(
              iconSize: 18,
              iconColor: SharePerksColors.textSecondaryLight,
              label: Text(
                viewAllLabel,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                ),
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
                  preview,
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
