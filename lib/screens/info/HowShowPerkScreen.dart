import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class HowShowPerkScreen extends StatelessWidget {
  const HowShowPerkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 5,
          children: [
            SizedBox(height: 60),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [Icon(HugeIconsSolid.arrowLeft02), Text('Back')],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'See how ',
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 22,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'we show perks at Shareperks',
                    style: TextStyle(
                      color: SharePerksColors.primary,
                      fontSize: 22,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'This is a description, this is a description, this is a description This is a description, this is a description, this is a description.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 20),
            Image.asset(
              Assets.ASSETS_SHOWPERKS_PNG,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
