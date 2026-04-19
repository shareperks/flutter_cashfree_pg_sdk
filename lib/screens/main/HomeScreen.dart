import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/border_card.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SvgPicture.asset(
          Assets.ASSETS_LOGO_SVG,
          height: 20,
          fit: BoxFit.contain,
        ),
      ),
      body: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              aspectRatio: 16 / 9,
              viewportFraction: 1.0,
            ),
            items: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SharePerksRadii.lg),
                  child: Container(
                    color: Colors.white,
                    child: Image.asset(
                      Assets.ASSETS_VALENTINE_GIFT_PNG,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SharePerksSpacing.sm),
          BorderCard(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            borderWidth: 1,
            color: SharePerksColors.primary.withValues(alpha: 0.3),
            borderRadius: SharePerksRadii.lg,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Himanshu',
                      style: TextStyle(
                        color: const Color(0xFF6400E0),
                        fontSize: 16,
                        fontFamily: 'Albert Sans',
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: SharePerksColors.backgroundLight,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          116,
                          123,
                          123,
                          123,
                        ).withValues(alpha: 0.1),
                        offset: Offset(0, 3),
                        blurRadius: 3,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
