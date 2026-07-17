import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton for [GiftCardCodeViewScreen]: banner card, meta rows, voucher block, footer cards.
class GiftCardCodeViewShimmer extends StatelessWidget {
  const GiftCardCodeViewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final inner = w - 32;
    final bannerH = inner / 2.65;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: [
            Column(
              spacing: 10,
              children: [
                ShimmerBuilder(width: inner, height: bannerH, radius: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    ShimmerBuilder(width: 72, height: 22, radius: 6),
                    ShimmerBuilder(width: inner * 0.72, height: 22, radius: 8),
                    ShimmerBuilder(width: inner, height: 14, radius: 6),
                    ShimmerBuilder(width: inner, height: 14, radius: 6),
                    ShimmerBuilder(width: inner * 0.88, height: 14, radius: 6),
                  ],
                ),
              ],
            ),
            ShimmerBuilder(width: inner, height: 152, radius: 12),
            ShimmerBuilder(width: inner, height: 88, radius: 12),
            ShimmerBuilder(width: inner, height: 112, radius: 14),
          ],
        ),
      ),
    );
  }
}
