import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/theme.dart';

class RewardLoader extends StatelessWidget {
  final double width;
  const RewardLoader({super.key, this.width = 165});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.start,
        runAlignment: WrapAlignment.start,
        alignment: WrapAlignment.start,
        children: List.generate(6, (index) {
          return RewardShimmerCard(width: width);
        }),
      ),
    );
  }
}

class RewardShimmerCard extends StatelessWidget {
  const RewardShimmerCard({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200.withAlpha(95)),
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
            child: ShimmerBuilder(radius: 0, width: width, height: 121),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    SizedBox(height: 5),
                    ShimmerBuilder(width: width, height: 25, radius: 8),
                    ShimmerBuilder(width: width / 1.5, height: 10, radius: 2),
                    ShimmerBuilder(width: width, height: 35, radius: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
