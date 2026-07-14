import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/theme.dart';

class VotBrandCard extends StatelessWidget {
  const VotBrandCard({
    super.key,
    required this.image,
    required this.name,
    required this.ticker,
    this.isSelected = false,
    this.isPreviouslyVoted = false,
    this.onTap,
    this.width = 150,
  });

  final String image;
  final String name;
  final String ticker;
  final bool isSelected;
  final bool isPreviouslyVoted;
  final VoidCallback? onTap;
  final double width;

  bool get _isHighlighted => isSelected || isPreviouslyVoted;

  Color get _borderColor {
    if (isSelected && isPreviouslyVoted) return SharePerksColors.primary;
    if (isSelected) return SharePerksColors.accent;
    if (isPreviouslyVoted) return SharePerksColors.primary.withValues(alpha: 0.45);
    return AppColors.neutral200;
  }

  double get _borderWidth {
    if (isSelected) return 2.5;
    if (isPreviouslyVoted) return 1.5;
    return 1.5;
  }

  Color? get _cardTint {
    if (isSelected && isPreviouslyVoted) {
      return SharePerksColors.primary.withValues(alpha: 0.06);
    }
    if (isSelected) return SharePerksColors.accent.withValues(alpha: 0.08);
    if (isPreviouslyVoted) {
      return SharePerksColors.primary.withValues(alpha: 0.05);
    }
    return AppColors.white;
  }

  List<BoxShadow>? get _shadow {
    if (!isSelected) return null;
    return [
      BoxShadow(
        color: (isPreviouslyVoted
                ? SharePerksColors.primary
                : SharePerksColors.accent)
            .withValues(alpha: 0.22),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        height: 180,
          decoration: BoxDecoration(
            color: _cardTint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor, width: _borderWidth),
            boxShadow: _shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Stack(
                  children: [
                    ImageBuilder(
                      imageUrl: image,
                      width: width,
                      height: 101,
                      fit: BoxFit.cover,
                    ),
                    if (_isHighlighted)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                (isSelected
                                        ? SharePerksColors.accent
                                        : SharePerksColors.primary)
                                    .withValues(alpha: 0.12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (isPreviouslyVoted || isSelected)
                      Positioned(
                        top: 10,
                        left: 8,
                        right: 8,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isPreviouslyVoted)
                              _VoteStatusChip(
                                label: 'Your vote',
                                backgroundColor: SharePerksColors.primary,
                                icon: HugeIconsSolid.tick04,
                              ),
                            if (isSelected)
                              _VoteStatusChip(
                                label: 'Selected',
                                backgroundColor: SharePerksColors.accent,
                                icon: isPreviouslyVoted
                                    ? HugeIconsSolid.tick04
                                    : HugeIconsSolid.starCircle,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isHighlighted
                              ? SharePerksColors.textPrimaryLight
                              : AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _isHighlighted
                                  ? SharePerksColors.primary
                                  : AppColors.neutral700,
                            ),
                      ),
                      if (isSelected &&
                          isPreviouslyVoted &&
                          name.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap Vote now to confirm',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w500,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      ] else if (isSelected && !isPreviouslyVoted) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to deselect',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: SharePerksFonts.inter,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      ] else if (isPreviouslyVoted && !isSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: SharePerksFonts.inter,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _VoteStatusChip extends StatelessWidget {
  const _VoteStatusChip({
    required this.label,
    required this.backgroundColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
