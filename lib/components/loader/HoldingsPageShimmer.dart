import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Shimmer placeholder matching the holdings layout (card, actions, list).
class HoldingsPageShimmer extends StatelessWidget {
  const HoldingsPageShimmer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final inner = width - 32;
    final half = (inner - 18) / 2;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            ShimmerBuilder(radius: 20, width: inner, height: 140),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      ShimmerBuilder(width: half, height: 42, radius: 8),
                      ShimmerBuilder(width: half, height: 42, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ShimmerBuilder(width: 160, height: 14, radius: 6),
                  ),
                  const SizedBox(height: 36),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBuilder(width: 130, height: 18, radius: 8),
                      const SizedBox(height: 14),
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Row(
                          children: [
                            ShimmerBuilder(width: 40, height: 40, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBuilder(
                                    width: inner * 0.55,
                                    height: 12,
                                    radius: 6,
                                  ),
                                  const SizedBox(height: 6),
                                  ShimmerBuilder(
                                    width: inner * 0.35,
                                    height: 10,
                                    radius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShimmerBuilder(
                                    width: 48,
                                    height: 10,
                                    radius: 4,
                                  ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: ShimmerBuilder(
                                      width: 40,
                                      height: 10,
                                      radius: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ShimmerBuilder(width: inner, height: 72, radius: 12),
            const SizedBox(height: 8),
            ShimmerBuilder(width: inner * 0.45, height: 14, radius: 6),
          ],
        ),
      ),
    );
  }
}
