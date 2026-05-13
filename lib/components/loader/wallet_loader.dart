import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton layout for [WalletScreen] (earnings, transactions, FAQs, footer).
class WalletPageShimmer extends StatelessWidget {
  const WalletPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 36;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        _EarningsCardShimmer(width: w),
        _TransactionSectionShimmer(width: w),
        ShimmerBuilder(width: w, height: 132, radius: 16),
        ShimmerBuilder(width: w, height: 88, radius: 12),
        ShimmerBuilder(width: w, height: 88, radius: 12),
      ],
    );
  }
}

/// Mimics the info [BorderCard] + collapse + wallet row + withdraw + banner.
class _EarningsCardShimmer extends StatelessWidget {
  const _EarningsCardShimmer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(58, 245, 248, 255),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 1,
          color: const Color.fromARGB(9, 81, 130, 254),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          ShimmerBuilder(width: width * 0.28, height: 18, radius: 6),
          ShimmerBuilder(width: width, height: 88, radius: 12),
          ShimmerBuilder(width: width, height: 44, radius: 10),
          ShimmerBuilder(width: width, height: 72, radius: 10),
        ],
      ),
    );
  }
}

/// Mimics transaction history card with stacked rows.
class _TransactionSectionShimmer extends StatelessWidget {
  const _TransactionSectionShimmer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: const Color.fromARGB(5, 51, 51, 51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          ShimmerBuilder(width: width * 0.45, height: 18, radius: 6),
          ...List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < 3 ? 10 : 0),
              child: Row(
                children: [
                  ShimmerBuilder(width: 28, height: 28, radius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        ShimmerBuilder(
                          width: width * 0.42,
                          height: 16,
                          radius: 6,
                        ),
                        ShimmerBuilder(
                          width: width * 0.32,
                          height: 12,
                          radius: 4,
                        ),
                      ],
                    ),
                  ),
                  ShimmerBuilder(width: 56, height: 14, radius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
