import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';

class EarningScreen extends StatelessWidget {
  const EarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Earnings"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.info,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: const Color(0x3F5182FE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text(
                          'Withdrawable Earnings',
                          style: TextStyle(
                            color: const Color(0xFF5182FE) /* Information */,
                            fontSize: 16,
                            fontFamily: SharePerksFonts.albertSans,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '42,600.00',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 22,
                            fontFamily: SharePerksFonts.albertSans,
                            fontWeight: FontWeight.w600,
                            height: 1.27,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF5283FE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          HugeIconsSolid.wallet01,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: SharePerksColors.borderLight,
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Pending earnings',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    '₹ 2,800.00',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 14,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: SharePerksColors.borderLight,
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Lifetime earnings',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    '₹ 2,800.00',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 14,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Image.asset(
                Assets.ASSETS_CARDS_TOP5PERCENTOFINVEST_PNG,
                width: MediaQuery.of(context).size.width,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BorderCard(
                    color: SharePerksColors.success,
                    width: (MediaQuery.of(context).size.width - 40) / 2,
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                    borderWidth: 1,
                    borderRadius: 16,
                    child: Column(
                      spacing: 5,
                      children: [
                        Image.asset(
                          Assets.ASSETS_ICONS_BENEFITS_PNG,
                          width: 90,
                        ),
                        Text(
                          'Total Earnings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 11.20,
                            fontFamily: SharePerksFonts.albertSans,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹ 64,800.00',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BorderCard(
                    color: SharePerksColors.accent,
                    width: (MediaQuery.of(context).size.width - 40) / 2,
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                    borderWidth: 1,
                    borderRadius: 16,
                    child: Column(
                      spacing: 5,
                      children: [
                        Image.asset(
                          Assets.ASSETS_ICONS_REFERRALS_PNG,
                          width: 90,
                        ),
                        Text(
                          'Total Earnings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 11.20,
                            fontFamily: SharePerksFonts.albertSans,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹ 64,800.00',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                child: Text("View Transaction History"),
              ),
              SizedBox(height: 20),
              ClickToHelp(),
              Copyright(),
            ],
          ),
        ),
      ),
    );
  }
}
