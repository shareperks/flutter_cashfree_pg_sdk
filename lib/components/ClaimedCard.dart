import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/theme.dart';

class ClaimedCard extends StatelessWidget {
  final bool expired;
  final String imageUrl;
  final String title;

  /// Pre-formatted value line from API (e.g. `₹ 10.00`, `₹ 0 OFF`).
  final String valueLine;

  /// Expiry label (e.g. `10 Mar 2027`) or placeholder when none.
  final String expiryLine;
  final Function()? onTap;
  final double width;
  const ClaimedCard({
    super.key,
    this.expired = false,
    this.imageUrl = '',
    this.title = '',
    this.valueLine = '',
    this.expiryLine = '—',
    this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: expired
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.neutral200,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Stack(
                children: [
                  ImageBuilder(
                    imageUrl: imageUrl,
                    width: width,
                    height: 121,
                    fit: BoxFit.cover,
                  ),
                  if (expired)
                    Positioned(
                      bottom: -1,
                      left: 0,
                      child: SvgPicture.asset(Assets.ASSETS_ICONS_EXPIRED_SVG),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                      ),
                      Text(
                        valueLine.isEmpty ? '—' : valueLine,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColors.neutral900,
                            ),
                      ),
                      Text(
                        "Ex: $expiryLine",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
