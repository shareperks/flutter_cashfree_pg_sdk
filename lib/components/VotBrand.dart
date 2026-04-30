import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/theme.dart';

class VotBrandCard extends StatelessWidget {
  const VotBrandCard({
    super.key,
    required this.image,
    required this.name,
    required this.ticker,
    required this.isVot,
    this.onTap,
    this.width = 150,
  });

  final String image;
  final String name;
  final String ticker;
  final bool isVot;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isVot ? AppColors.brand : AppColors.neutral200,
            width: isVot ? 2 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  ImageBuilder(
                    imageUrl: image,
                    width: width,
                    height: 101,
                    fit: BoxFit.cover,
                  ),
                  if (isVot)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(
                        HugeIconsSolid.tick04,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ticker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
    );
  }
}
