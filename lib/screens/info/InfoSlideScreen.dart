import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

class InfoSlideScreen extends StatelessWidget {
  InfoSlideScreen({super.key});
  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 35,
        title: Text(
          "Back",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: SharePerksFonts.inter,
            color: SharePerksColors.primary,
          ),
        ),
        leading: TextButton(
          onPressed: () {
            if (pageController.page == 0) {
              context.pop();
            } else {
              pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Icon(HugeIconsSolid.arrowLeft02, size: 22),
        ),
      ),
      body: PageView(
        controller: pageController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Image.asset(
                  Assets.ASSETS_SPLASH_STEP1_PNG,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 20,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.LINK_DEMAT_INFO_SCREEN);
                      },
                      child: Text('Connect brokerage'),
                    ),
                    TextButton(
                      onPressed: () {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text('I’ll do it later'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  Assets.ASSETS_SPLASH_STEP3_PNG,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                ),
                SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    context.pushNamed(RouteNames.HOW_SHOW_PERK_SCREEN);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    decoration: BoxDecoration(
                      color: SharePerksColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SharePerksColors.borderLight),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'See how ',
                            style: TextStyle(
                              color: const Color(0xFFFF4AA7),
                              fontSize: 12,
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'we show perks at Shareperks',
                            style: TextStyle(
                              color: const Color(0xFF6400E0),
                              fontSize: 12,
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 20,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                Image.asset(
                  Assets.ASSETS_SPLASH_STEP2_PNG,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 20,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.goNamed(RouteNames.HOME_SCREEN);
                      },
                      child: Text('Let’s go'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
