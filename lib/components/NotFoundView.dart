import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class NotFoundView extends StatelessWidget {
  final String subtitle;
  const NotFoundView({super.key, this.subtitle = "in this category."});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(
              HugeIconsSolid.packageOpen,
              size: 80,
              color: SharePerksColors.textSecondaryLight,
            ),
            SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'No active perks',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' $subtitle',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 16,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: Text('Request Your Perk')),
          ],
        ),
      ),
    );
  }
}
