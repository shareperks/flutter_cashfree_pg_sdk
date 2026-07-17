import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/theme.dart';

import 'rewardloader.dart';

class BrandViewLoader extends StatelessWidget {
  const BrandViewLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const cardWidth = 165.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBuilder(radius: 0, width: width, height: 180),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerBuilder(width: 70, height: 18, radius: 8),
                    SizedBox(width: 10),
                    ShimmerBuilder(width: 140, height: 18, radius: 8),
                  ],
                ),
                const SizedBox(height: 10),
                const ShimmerBuilder(
                  width: double.infinity,
                  height: 12,
                  radius: 6,
                ),
                const SizedBox(height: 8),
                ShimmerBuilder(width: width * 0.85, height: 12, radius: 6),
                const SizedBox(height: 8),
                ShimmerBuilder(width: width * 0.65, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(height: SharePerksSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(SharePerksRadii.lg),
                border: Border.all(color: AppColors.neutral200.withAlpha(95)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        ShimmerBuilder(width: 110, height: 18, radius: 8),
                        Spacer(),
                        ShimmerBuilder(width: 70, height: 14, radius: 8),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 2,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return RewardShimmerCard(width: cardWidth);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
