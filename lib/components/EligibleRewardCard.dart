import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/screens/rewards/utils/reward_eligibility.dart';

enum RewardRateKind { giftCard, cashback, promoCode }

/// Shared copy + formatting for 3-tier reward rates.
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

  /// Explains which tier applies.
  ///
  /// Shareholder = maximum · Member = any holding · Standard = no holding.
  static String ratesDescription({
    required RewardEligibilityTier tier,
    bool listedOnExchange = true,
  }) {
    final label = resolveRewardRateLabel(
      tier: tier,
      listedOnExchange: listedOnExchange,
    );
    switch (label) {
      case RewardRateLabel.shareholder:
        return 'Shareholder Reward is the maximum rate for meeting this perk’s '
            'holding criteria. It applies to you.';
      case RewardRateLabel.member:
        return listedOnExchange
            ? 'Member Reward applies when you have any holdings connected. '
                'Hold the required shares to unlock the Shareholder Reward '
                '(maximum).'
            : 'Member Reward applies when you have connected holdings. '
                'It applies to you for this perk.';
      case RewardRateLabel.standard:
        return listedOnExchange
            ? 'Standard Reward applies when you have no holdings for this perk. '
                'Connect your broker to unlock Member Reward (any holding) or '
                'Shareholder Reward (maximum).'
            : 'Standard Reward applies when you have no holdings connected. '
                'Connect your broker to unlock the Member Reward.';
    }
  }
}

/// Top eligibility banner — uses the same label + rate as [RewardRatesSection].
class RewardEligibilityBanner extends StatelessWidget {
  final bool isEligible;
  final bool isBrokerageEligible;
  final bool listedOnExchange;
  final bool reqReimport;
  final num? withHolderRewardRate;
  final num? withAnyHoldingRewardRate;
  final num? nonHolderRewardRate;
  final String? rewardType;

  /// When false, Standard tier shows no banner (detail screens).
  /// Claim screens may set true to always show the active tier.
  final bool showStandardBanner;

  const RewardEligibilityBanner({
    super.key,
    required this.isEligible,
    this.isBrokerageEligible = false,
    this.listedOnExchange = true,
    this.reqReimport = false,
    this.withHolderRewardRate,
    this.withAnyHoldingRewardRate,
    this.nonHolderRewardRate,
    this.rewardType,
    this.showStandardBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final tier = resolveRewardTier(
      isEligible: isEligible,
      isBrokerageEligible: isBrokerageEligible,
      reqReimport: reqReimport,
    );
    final label = resolveRewardRateLabel(
      tier: tier,
      listedOnExchange: listedOnExchange,
    );

    if (label == RewardRateLabel.standard && !showStandardBanner) {
      return const SizedBox.shrink();
    }

    final rate = activeRewardDisplayRate(
      tier: tier,
      listedOnExchange: listedOnExchange,
      withHolderRewardRate: withHolderRewardRate,
      withAnyHoldingRewardRate: withAnyHoldingRewardRate,
      nonHolderRewardRate: nonHolderRewardRate,
    );

    return _RewardTierBanner(
      label: label,
      rewardRatePercent: rate,
      rewardType: rewardType,
      listedOnExchange: listedOnExchange,
    );
  }
}

/// Shared visual for Shareholder / Member / Standard eligibility.
class _RewardTierBanner extends StatelessWidget {
  final RewardRateLabel label;
  final num? rewardRatePercent;
  final String? rewardType;
  final bool listedOnExchange;

  const _RewardTierBanner({
    required this.label,
    required this.rewardRatePercent,
    this.rewardType,
    this.listedOnExchange = true,
  });

  @override
  Widget build(BuildContext context) {
    final kind = RewardRateUi.kindFor(rewardType);
    final rateText = RewardRateUi.formatRate(rewardRatePercent);
    final hasRate = RewardRateUi.hasRate(rewardRatePercent);
    final rateSuffix = RewardRateUi.rateSuffix(kind);

    final Color accent;
    final IconData icon;
    switch (label) {
      case RewardRateLabel.shareholder:
        accent = SharePerksColors.accent;
        icon = HugeIconsSolid.checkmarkCircle02;
        break;
      case RewardRateLabel.member:
        accent = listedOnExchange
            ? SharePerksColors.primary
            : SharePerksColors.accent;
        icon = HugeIconsSolid.analyticsUp;
        break;
      case RewardRateLabel.standard:
        accent = SharePerksColors.primary;
        icon = HugeIconsSolid.checkmarkCircle02;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RewardRateUi.gutter,
        16,
        RewardRateUi.gutter,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label.title,
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 15,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
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
                      color: accent,
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

/// Body section comparing Shareholder / Member / Standard reward rates.
class RewardRatesSection extends StatelessWidget {
  final num? shareholderRate;
  final num? brokerageRate;
  final num? nonShareholderRate;
  final bool isEligible;
  final bool isBrokerageEligible;
  final bool listedOnExchange;
  final bool reqReimport;
  final String? rewardType;

  const RewardRatesSection({
    super.key,
    required this.shareholderRate,
    required this.nonShareholderRate,
    required this.isEligible,
    this.brokerageRate,
    this.isBrokerageEligible = false,
    this.listedOnExchange = true,
    this.reqReimport = false,
    this.rewardType,
  });

  @override
  Widget build(BuildContext context) {
    final kind = RewardRateUi.kindFor(rewardType);
    final suffix = RewardRateUi.rateSuffix(kind);
    final tier = resolveRewardTier(
      isEligible: isEligible,
      isBrokerageEligible: isBrokerageEligible,
      reqReimport: reqReimport,
    );
    final activeLabel = resolveRewardRateLabel(
      tier: tier,
      listedOnExchange: listedOnExchange,
    );

    // Listed: Shareholder + optional Member + Standard.
    // Non-listed: Member + Standard only.
    final showShareholder = listedOnExchange;
    final showMember = listedOnExchange
        ? shouldShowBrokerageRateRow(
            listedOnExchange: listedOnExchange,
            withAnyHoldingRewardRate: brokerageRate,
          )
        : true;

    final memberRate = memberRewardDisplayRate(
      listedOnExchange: listedOnExchange,
      withHolderRewardRate: shareholderRate,
      withAnyHoldingRewardRate: brokerageRate,
    );

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
          RewardRateUi.ratesDescription(
            tier: tier,
            listedOnExchange: listedOnExchange,
          ),
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
              if (showShareholder)
                _RateLine(
                  label: RewardRateLabel.shareholder.title,
                  value: RewardRateUi.formatRateLine(shareholderRate, suffix),
                  isActive: activeLabel == RewardRateLabel.shareholder,
                  accent: SharePerksColors.accent,
                  showDivider: true,
                ),
              if (showMember)
                _RateLine(
                  label: RewardRateLabel.member.title,
                  value: RewardRateUi.formatRateLine(memberRate, suffix),
                  isActive: activeLabel == RewardRateLabel.member,
                  accent: listedOnExchange
                      ? SharePerksColors.primary
                      : SharePerksColors.accent,
                  showDivider: true,
                ),
              _RateLine(
                label: RewardRateLabel.standard.title,
                value: RewardRateUi.formatRateLine(nonShareholderRate, suffix),
                isActive: activeLabel == RewardRateLabel.standard,
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
