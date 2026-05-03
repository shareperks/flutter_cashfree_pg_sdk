import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';

class ReferAndEarnCodeScreen extends StatelessWidget {
  const ReferAndEarnCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SharePerksColors.primary,
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Refer & Earn"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        child: Column(
          spacing: 20,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                Assets.ASSETS_CARDS_REFERANDEARNSTEPS_PNG,
                width: MediaQuery.of(context).size.width,
              ),
            ),

            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(18),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x3FFFFFFF),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ReferCodeCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReferCodeCard extends StatelessWidget {
  const ReferCodeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      isGradientBackground: false,
      borderWidth: 1,
      borderRadius: 18,
      color: AppColors.brand.withAlpha((50)),
      child: Column(
        children: [
          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              Container(
                width: 230,
                height: 48.26,
                padding: const EdgeInsets.symmetric(
                  horizontal: 62,
                  vertical: 7,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 7.80,
                      offset: Offset(0, 4.80),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'FGC563',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF6400E0),
                    fontSize: 26.71,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  HugeIconsStroke.copy01,
                  color: SharePerksColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Let your friends know you’ve leveled up:',
            style: TextStyle(
              color: const Color(0xFF898989),
              fontSize: 12,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  HugeIconsSolid.whatsapp,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  HugeIconsSolid.facebook01,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  HugeIconsSolid.share08,
                  size: 28,
                  color: SharePerksColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClickToHelp(),
        ],
      ),
    );
  }
}
