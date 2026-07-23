import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

enum RewardRateKind { giftCard, cashback, promoCode }

/// Shared copy + formatting for shareholder / non-shareholder rates.
abstract final class RewardRateUi {
  static const double gutter = 20;

  static RewardRateKind kindFor(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'BENEFIT':
      case 'CASHBACK':
        return RewardRateKind.cashback;
      case 'OFFER':
      case 'PROMOCODE':
      case 'PROMO':
        return RewardRateKind.promoCode;
      default:
        return RewardRateKind.giftCard;
    }
  }

  static String perkLabel(RewardRateKind kind) {
    switch (kind) {
      case RewardRateKind.cashback:
        return 'Cashback';
      case RewardRateKind.promoCode:
        return 'Promo code';
      case RewardRateKind.giftCard:
        return 'Gift card';
    }
  }

  static String rateSuffix(RewardRateKind kind) {
    switch (kind) {
      case RewardRateKind.cashback:
        return 'cashback';
      case RewardRateKind.promoCode:
      case RewardRateKind.giftCard:
        return 'off';
    }
  }

  static String formatRate(num? rate) {
    if (rate == null) return '—';
    final value = rate.toDouble();
    if (value == value.truncateToDouble()) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatRateLine(num? rate, String suffix) {
    if (rate == null) return '—';
    return '${formatRate(rate)} $suffix';
  }

  static bool hasRate(num? rate) => rate != null && rate > 0;

  /// Explains why two reward rates exist and which applies to the user.
  static String ratesDescription({required bool isEligible}) {
    if (isEligible) {
      return 'Brands on SharePerks reward shareholders with better perks '
          'because you invest in them. Since you hold shares in this company, '
          'the shareholder rate applies to you.';
    }
    return 'Brands on SharePerks reward shareholders with better perks '
        'because you invest in them. You can still claim this perk at the '
        'standard rate—or link your broker to verify holdings and unlock '
        'the shareholder rate.';
  }
}

/// Top banner when the user is an eligible shareholder.
class EligibleRewardCard extends StatelessWidget {
  final num? rewardRatePercent;
  final String? rewardType;

  const EligibleRewardCard({
    super.key,
    required this.rewardRatePercent,
    this.rewardType,
  });

  @override
  Widget build(BuildContext context) {
    final kind = RewardRateUi.kindFor(rewardType);
    final rateText = RewardRateUi.formatRate(rewardRatePercent);
    final hasRate = RewardRateUi.hasRate(rewardRatePercent);
    final perkLabel = RewardRateUi.perkLabel(kind);
    final rateSuffix = RewardRateUi.rateSuffix(kind);

    return Padding(
      padding: const EdgeInsets.fromLTRB(RewardRateUi.gutter, 16, RewardRateUi.gutter, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SharePerksColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SharePerksColors.accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                HugeIconsSolid.checkmarkCircle02,
                size: 22,
                color: SharePerksColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eligible shareholder',
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 11,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your $perkLabel rate is unlocked',
                    style: TextStyle(
                      color: SharePerksColors.textPrimaryLight,
                      fontSize: 15,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (!hasRate) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Shareholder benefits apply to this perk.',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasRate) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rateText,
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 28,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rateSuffix,
                    style: TextStyle(
                      color: SharePerksColors.textSecondaryLight,
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Body section comparing shareholder vs non-shareholder reward rates.
class RewardRatesSection extends StatelessWidget {
  final num? shareholderRate;
  final num? nonShareholderRate;
  final bool isEligible;
  final String? rewardType;

  const RewardRatesSection({
    super.key,
    required this.shareholderRate,
    required this.nonShareholderRate,
    required this.isEligible,
    this.rewardType,
  });

  @override
  Widget build(BuildContext context) {
    final kind = RewardRateUi.kindFor(rewardType);
    final suffix = RewardRateUi.rateSuffix(kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reward rates',
          style: TextStyle(
            color: SharePerksColors.textPrimaryLight,
            fontSize: 14,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          RewardRateUi.ratesDescription(isEligible: isEligible),
          style: TextStyle(
            color: SharePerksColors.textSecondaryLight,
            fontSize: 12,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: SharePerksColors.surfaceLight,
            borderRadius: BorderRadius.circular(SharePerksRadii.lg),
          ),
          child: Column(
            children: [
              _RateLine(
                label: 'Shareholder rate',
                value: RewardRateUi.formatRateLine(shareholderRate, suffix),
                isActive: isEligible,
                accent: SharePerksColors.accent,
                showDivider: true,
              ),
              _RateLine(
                label: 'Non-shareholder rate',
                value: RewardRateUi.formatRateLine(nonShareholderRate, suffix),
                isActive: !isEligible,
                accent: SharePerksColors.primary,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RateLine extends StatelessWidget {
  const _RateLine({
    required this.label,
    required this.value,
    required this.isActive,
    required this.accent,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool isActive;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: isActive ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 15,
                  child: isActive
                      ? Container(
                          width: 3,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: SharePerksColors.textPrimaryLight,
                          fontSize: 13,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Applies to you',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isActive
                        ? accent
                        : SharePerksColors.textPrimaryLight,
                    fontSize: 15,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: SharePerksColors.borderLight.withValues(alpha: 0.85),
          ),
      ],
    );
  }
}
