import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';

class ClaimedPerksScreen extends StatelessWidget {
  const ClaimedPerksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
        title: Text("Claimed Perks"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BorderCard(
                  width: (MediaQuery.of(context).size.width / 2) - 20,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  borderWidth: 1,
                  borderRadius: 18,
                  color: AppColors.brand,
                  child: Column(
                    spacing: 6,
                    children: [
                      Text(
                        'Total Value Saved',
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '₹ 3,400.00',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 22,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹650+ this month',
                        style: TextStyle(
                          color: const Color(0xFF898989),
                          fontSize: 9.60,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),

                BorderCard(
                  width: (MediaQuery.of(context).size.width / 2) - 20,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  borderWidth: 1,
                  borderRadius: 18,
                  color: AppColors.brand,
                  child: Column(
                    spacing: 6,
                    children: [
                      Text(
                        'Total Perks Claimed',
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '74',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 22,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '25 this month',
                        style: TextStyle(
                          color: const Color(0xFF898989),
                          fontSize: 9.60,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Image.asset(
              Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
              width: MediaQuery.of(context).size.width,
            ),
          ],
        ),
      ),
    );
  }
}
