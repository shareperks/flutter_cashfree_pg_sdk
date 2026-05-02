import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton rows for [FAQsScreen] while FAQs load (mirrors [FaqItem] layout).
class FaqListShimmer extends StatelessWidget {
  const FaqListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final w =
        MediaQuery.sizeOf(context).width - 46; // screen padding 18*2 + list 5*2

    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          _FaqShimmerRow(width: w),
          if (i < itemCount - 1) const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _FaqShimmerRow extends StatelessWidget {
  const _FaqShimmerRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: SharePerksColors.borderLight,
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBuilder(width: width * 0.68, height: 12, radius: 6),
          const SizedBox(height: 10),
          ShimmerBuilder(width: width, height: 10, radius: 5),
          const SizedBox(height: 6),
          ShimmerBuilder(width: width * 0.82, height: 10, radius: 5),
          const SizedBox(height: 6),
          ShimmerBuilder(width: width * 0.45, height: 10, radius: 5),
        ],
      ),
    );
  }
}
