import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/gradient_badge.dart';
import 'package:soui/theme.dart';

class InvestmentAmountCard extends StatelessWidget {
  const InvestmentAmountCard({
    super.key,
    required this.amount,
    required this.snapshotDate,
    required this.isPrimary,
    required this.isExpired,
  });

  final String amount;
  final String snapshotDate;
  final bool isPrimary;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(25),
          height: 140,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(1.00, 0.89),
              end: Alignment(0.00, 0.11),
              colors: [const Color(0xFF6400E0), const Color(0xFF37007A)],
            ),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 0, color: SharePerksColors.secondary),
              borderRadius: BorderRadius.circular(20),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x666500E0),
                blurRadius: 16,
                offset: Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Portfolio',
                style: TextStyle(
                  color: Colors.white.withAlpha(95),
                  fontSize: 16,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                  height: 1.27,
                ),
              ),
              Row(
                spacing: 5,
                children: [
                  Text(
                    'Last Snapshot Date:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    snapshotDate,
                    style: TextStyle(
                      color: isExpired
                          ? const Color(0xFFFFCC80)
                          : Colors.white.withAlpha(90),
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isExpired)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: GradientBadge(title: 'Expired', color: AppColors.error),
            ),
          ),
        if (isPrimary && !isExpired)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: GradientBadge(title: 'Primary', color: AppColors.success),
            ),
          ),
      ],
    );
  }
}
