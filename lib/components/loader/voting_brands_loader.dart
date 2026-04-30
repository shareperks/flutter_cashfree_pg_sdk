import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/elements/border_card.dart';

/// Shimmer placeholder for [VotingBrands] while listing data loads.
class VotingBrandsLoader extends StatelessWidget {
  const VotingBrandsLoader({super.key});

  static const double _cardW = 150;
  static const double _cardH = 180;

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      borderWidth: 1,
      borderRadius: 16,
      color: SharePerksColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBuilder(width: 150, height: 18, radius: 8),
                    SizedBox(height: 10),
                    ShimmerBuilder(width: 90, height: 18, radius: 8),
                    SizedBox(height: 10),
                    ShimmerBuilder(width: 130, height: 18, radius: 8),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    ShimmerBuilder(width: 100, height: 34, radius: 8),
                    SizedBox(height: 10),
                    ShimmerBuilder(width: 148, height: 12, radius: 6),
                    SizedBox(height: 8),
                    ShimmerBuilder(width: 132, height: 12, radius: 6),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: _cardH,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => const ShimmerBuilder(
                width: _cardW,
                height: _cardH,
                radius: 18,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: ShimmerBuilder(
              width: double.infinity,
              height: 48,
              radius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
