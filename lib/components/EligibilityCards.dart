import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/border_card.dart';

class EligibilityCardsData {
  final int holdingPeriodDays;
  final int sharesRequired;
  final int renewEveryDays;
  final String title;

  const EligibilityCardsData({
    required this.holdingPeriodDays,
    required this.sharesRequired,
    required this.renewEveryDays,
    this.title = 'Eligibility',
  });

  static const EligibilityCardsData placeholder = EligibilityCardsData(
    holdingPeriodDays: 30,
    sharesRequired: 5,
    renewEveryDays: 120,
  );
}

String _pluralize(int count, String singular) =>
    count == 1 ? singular : '${singular}s';

class EligibilityCards extends StatelessWidget {
  const EligibilityCards({
    super.key,
    this.data = EligibilityCardsData.placeholder,
  });

  final EligibilityCardsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: TextStyle(
            color: const Color(0xFF6400E0),
            fontSize: 15,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BorderCard(
              color: SharePerksColors.primary.withAlpha(32),
              width: (MediaQuery.of(context).size.width / 3) - 25,
              height: 100,
              borderRadius: 10,
              borderWidth: 1,
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        '${data.holdingPeriodDays}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 15,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _pluralize(data.holdingPeriodDays, 'Day'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 15,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Holding\nPeriod',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            BorderCard(
              color: SharePerksColors.accent.withAlpha(32),
              width: (MediaQuery.of(context).size.width / 3) - 25,
              height: 100,
              borderRadius: 10,
              borderWidth: 1,
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${data.sharesRequired}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 18,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_pluralize(data.sharesRequired, 'Share')}\nRequired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            BorderCard(
              color: SharePerksColors.primary.withAlpha(32),
              width: (MediaQuery.of(context).size.width / 3) - 25,
              height: 100,
              borderRadius: 10,
              borderWidth: 1,
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 2,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Opacity(
                              opacity: 0.50,
                              child: Text(
                                'Every',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF6400E0),
                                  fontSize: 7,
                                  fontFamily: SharePerksFonts.inter,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 2,
                        children: [
                          Text(
                            '${data.renewEveryDays}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF6400E0),
                              fontSize: 15,
                              fontFamily: SharePerksFonts.albertSans,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _pluralize(data.renewEveryDays, 'Day'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF333333),
                              fontSize: 15,
                              fontFamily: SharePerksFonts.albertSans,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Reward\nRenews',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
