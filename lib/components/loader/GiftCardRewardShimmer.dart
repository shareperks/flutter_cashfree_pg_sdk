import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Shimmer placeholder for `GiftCardRewardScreen` layout.
class GiftCardRewardShimmer extends StatelessWidget {
  const GiftCardRewardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final inner = width - 28; // matches screen padding (14 * 2)

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info card
            ShimmerBuilder(width: inner, height: 160, radius: 18),
            const SizedBox(height: 14),

            // CTA buttons placeholders
            Center(
              child: ShimmerBuilder(
                width: MediaQuery.of(context).size.width,
                height: 42,
                radius: 10,
              ),
            ),
            const SizedBox(height: 10),
            ShimmerBuilder(width: 220, height: 18, radius: 8),

            const SizedBox(height: 18),

            // Terms header
            ShimmerBuilder(width: inner * 0.55, height: 16, radius: 8),
            const SizedBox(height: 10),

            // Terms card
            ShimmerBuilder(width: inner, height: 86, radius: 14),
            const SizedBox(height: 12),

            // A couple more content blocks
            ShimmerBuilder(width: inner * 0.8, height: 14, radius: 7),
            const SizedBox(height: 8),
            ShimmerBuilder(width: inner * 0.65, height: 14, radius: 7),
            const SizedBox(height: 18),
            ShimmerBuilder(width: inner, height: 140, radius: 16),
          ],
        ),
      ),
    );
  }
}
