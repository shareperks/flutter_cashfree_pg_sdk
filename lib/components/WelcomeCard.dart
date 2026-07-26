import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/theme.dart';

/// Home / unlocked summary: active perks, new rewards, Member unlocked.
class RewardCountCard extends StatelessWidget {
  final String activePerks;
  final String newRewards;

  /// Brokerage-only / non-Shareholder unlocks (`anyRewardsEligible` bucket).
  final int memberUnlocked;

  const RewardCountCard({
    super.key,
    required this.activePerks,
    required this.newRewards,
    this.memberUnlocked = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadows: [
          BoxShadow(
            color: Color.fromARGB(17, 67, 0, 148),
            blurRadius: 4,
            offset: Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'You have',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$activePerks active perks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
              if (memberUnlocked > 0)
                _UnlockedCountChip(
                  label: 'Shareholder',
                  count: memberUnlocked,
                  color: SharePerksColors.primary,
                ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$newRewards new reward',
                      style: TextStyle(
                        color: const Color(0xFF6400E0),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                    TextSpan(
                      text: 'unlocked this week',
                      style: TextStyle(
                        color: const Color(0xFF898989),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -12,
            top: -12,
            child: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    if (activePerks == "0") {
                      context.pushNamed(RouteNames.REQUEST_PERK_SCREEN);
                      return;
                    }
                    context.pushNamed(RouteNames.UNLOCKED_PERKS_SCREEN);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        activePerks == "0" ? 'Request a perk' : 'View all',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                      Icon(
                        HugeIconsSolid.arrowRight02,
                        size: 15,
                        color: AppColors.brand,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedCountChip extends StatelessWidget {
  const _UnlockedCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label Perks',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: SharePerksFonts.inter,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
