import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class FaqItem extends StatelessWidget {
  final bool showBorder;
  final String question;
  final String answer;

  const FaqItem({
    super.key,
    this.showBorder = false,
    this.question = 'What is the Wallets section?',
    this.answer =
        'This is where you connect and verify your Demat holdings to unlock eligible shareholder perks.',
  });

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
          question,
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
            answer,
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
