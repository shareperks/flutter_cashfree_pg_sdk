import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';

/// Explains Shareholder / Brokerage / Standard reward tiers.
class RewardTiersInfoScreen extends StatelessWidget {
  const RewardTiersInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Reward types'),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How SharePerks rewards work',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your reward rate depends on your holdings. We apply the best tier you qualify for, from highest to lowest.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _TierCard(
              accent: SharePerksColors.accent,
              icon: HugeIconsSolid.starCircle,
              title: 'Shareholder Reward',
              subtitle: 'Maximum reward',
              body:
                  'You meet this perk’s specific holding criteria (quantity, days, or other rules). This is the highest reward rate available for the perk.',
            ),
            const SizedBox(height: 12),
            _TierCard(
              accent: SharePerksColors.primary,
              icon: HugeIconsSolid.analyticsUp,
              title: 'Brokerage Reward',
              subtitle: 'Any-holding reward',
              body:
                  'Your broker is connected and you have holdings, but you don’t meet the full shareholder criteria for this perk. You still unlock a mid-tier reward rate.',
            ),
            const SizedBox(height: 12),
            _TierCard(
              accent: SharePerksColors.textSecondaryLight,
              icon: HugeIconsSolid.giftCard,
              title: 'Standard Reward',
              subtitle: 'No holding reward for this perk',
              body:
                  'You don’t hold (or don’t qualify for) this perk’s holdings. You can still claim it at the base standard reward rate.',
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SharePerksColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Priority is always Shareholder → Brokerage → Standard. If you qualify for a higher tier, that rate is applied automatically.',
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TierCard({
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 15,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: SharePerksColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
