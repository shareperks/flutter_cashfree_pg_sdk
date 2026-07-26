import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ImageBuilder.dart';

class ClaimedCard extends StatelessWidget {
  final bool expired;
  final bool used;
  final String imageUrl;
  final String title;

  /// Pre-formatted value line from API (e.g. `₹ 10.00`, `₹ 0 OFF`).
  final String valueLine;

  /// Expiry label (e.g. `10 Mar 2027`) or placeholder when none.
  final String expiryLine;

  /// Optional type label, e.g. Gift Card / Discount.
  final String? typeLabel;
  final Function()? onTap;
  final double width;

  const ClaimedCard({
    super.key,
    this.expired = false,
    this.used = false,
    this.imageUrl = '',
    this.title = '',
    this.valueLine = '',
    this.expiryLine = '—',
    this.typeLabel,
    this.onTap,
    this.width = 160,
  });

  Color get _borderColor {
    if (expired) return SharePerksColors.warning.withValues(alpha: 0.45);
    if (used) return SharePerksColors.borderLight;
    return SharePerksColors.primary.withValues(alpha: 0.22);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SharePerksColors.backgroundLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Stack(
                  children: [
                    ImageBuilder(
                      imageUrl: imageUrl,
                      width: width,
                      height: 118,
                      fit: BoxFit.cover,
                    ),
                    if (used || expired)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusPill(
                          label: expired ? 'Expired' : 'Used',
                          color: expired
                              ? SharePerksColors.warning
                              : SharePerksColors.textSecondaryLight,
                        ),
                      ),
                    if (expired)
                      Positioned(
                        bottom: -1,
                        left: 0,
                        child: SvgPicture.asset(
                          Assets.ASSETS_ICONS_EXPIRED_SVG,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (typeLabel != null && typeLabel!.trim().isNotEmpty) ...[
                      Text(
                        typeLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SharePerksColors.primary,
                          fontSize: 10,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 13,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valueLine.isEmpty ? '—' : valueLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          HugeIconsSolid.calendar03,
                          size: 12,
                          color: expired
                              ? SharePerksColors.warning
                              : SharePerksColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            expiryLine.isEmpty ? 'No expiry' : expiryLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: expired
                                  ? SharePerksColors.warning
                                  : SharePerksColors.textSecondaryLight,
                              fontSize: 10,
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: SharePerksFonts.inter,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
