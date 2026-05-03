import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton for [ClaimedPerksScreen] while my-claimed data loads.
class ClaimedPerksShimmer extends StatelessWidget {
  const ClaimedPerksShimmer({super.key, this.perkCardCount = 4});

  final int perkCardCount;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final leftStatW = (w / 2) - 20;
    final rightStatW = (w / 2) - 23;
    final perkW = rightStatW;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBuilder(width: leftStatW, height: 108, radius: 18),
            ShimmerBuilder(width: rightStatW, height: 108, radius: 18),
          ],
        ),
        const SizedBox(height: 20),
        ShimmerBuilder(width: w, height: 52, radius: 12),
        const SizedBox(height: 12),
        ShimmerBuilder(width: w, height: 40, radius: 10),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(
            perkCardCount,
            (_) => ShimmerBuilder(width: perkW, height: 210, radius: 12),
          ),
        ),
      ],
    );
  }
}
