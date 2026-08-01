import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/theme.dart';

class BrandCard extends StatelessWidget {
  final bool isNew;
  final String imageUrl;
  final String title;
  final Function()? onTap;
  final double width;
  const BrandCard({
    super.key,
    this.isNew = false,
    this.imageUrl = '',
    this.title = '',
    this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  ImageBuilder(
                    imageUrl: imageUrl,
                    width: width,
                    height: 121,
                    fit: BoxFit.cover,
                  ),
                  if (isNew)
                    Positioned(
                      bottom: -1,
                      left: 0,
                      child: SvgPicture.asset(
                        Assets.ASSETS_ICONS_NEWADDITIONS_SVG,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
