import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class FaqItem extends StatelessWidget {
  final bool showBorder;
  const FaqItem({super.key, this.showBorder = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  width: 1,
                  color: SharePerksColors.borderLight,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Text(
          'What is the Wallets section?',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 12,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'This is where you connect and verify your Demat holdings to unlock eligible shareholder perks.',
            style: TextStyle(
              color: const Color(0xFF898989),
              fontSize: 10,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
