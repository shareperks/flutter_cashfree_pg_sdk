import 'package:flutter/material.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/theme.dart';

class BrandPageLoader extends StatelessWidget {
  final double width;
  const BrandPageLoader({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(6, (_) => _BrandShimmerCard(width: width)),
      ),
    );
  }
}

class _BrandShimmerCard extends StatelessWidget {
  final double width;
  const _BrandShimmerCard({required this.width});

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
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: ShimmerBuilder(radius: 0, width: width, height: 121),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShimmerBuilder(width: width * 0.7, height: 14, radius: 8),
                    const SizedBox(height: 10),
                    ShimmerBuilder(width: width * 0.35, height: 12, radius: 6),
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

