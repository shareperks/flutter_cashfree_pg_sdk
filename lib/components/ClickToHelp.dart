import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class ClickToHelp extends StatelessWidget {
  const ClickToHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          Text(
            'Need help?',
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 12,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'Click here.',
            style: TextStyle(
              color: SharePerksColors.accent,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.underline,
              decorationColor: SharePerksColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
