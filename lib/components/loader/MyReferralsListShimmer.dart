import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton for [MyReferralListScreen]: search/sort bar + referral rows.
class MyReferralsListShimmer extends StatelessWidget {
  const MyReferralsListShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final barW = w - 88;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ShimmerBuilder(width: barW, height: 48, radius: 12),
              const SizedBox(width: 5),
              ShimmerBuilder(width: 44, height: 44, radius: 10),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(rowCount, (_) => _ReferralRowShimmer(totalWidth: w)),
        ],
      ),
    );
  }
}

class _ReferralRowShimmer extends StatelessWidget {
  const _ReferralRowShimmer({required this.totalWidth});

  final double totalWidth;

  @override
  Widget build(BuildContext context) {
    final textBlockW = totalWidth - 48 - 14 * 2 - 12 - 88;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SharePerksColors.borderLight.withAlpha(50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerBuilder(width: 48, height: 48, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBuilder(
                    width: textBlockW.clamp(120, 220),
                    height: 15,
                    radius: 6,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBuilder(width: 96, height: 12, radius: 6),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBuilder(width: 88, height: 22, radius: 4),
                const SizedBox(height: 6),
                ShimmerBuilder(width: 72, height: 10, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
