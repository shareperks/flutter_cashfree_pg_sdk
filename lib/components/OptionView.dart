import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class OptionView extends StatelessWidget {
  String image;
  String title;
  OptionView({super.key, required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(image, width: 75, height: 75),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SharePerksColors.surfaceDark,
              fontSize: 12,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
