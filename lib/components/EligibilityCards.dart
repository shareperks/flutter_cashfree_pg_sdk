import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/border_card.dart';

class EligibilityCards extends StatelessWidget {
  const EligibilityCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eligibility',
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
                        '30',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 15,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Days',
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
                    '5',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 18,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Shares\nRequired',
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
                            '120',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF6400E0),
                              fontSize: 15,
                              fontFamily: SharePerksFonts.albertSans,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Days',
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
