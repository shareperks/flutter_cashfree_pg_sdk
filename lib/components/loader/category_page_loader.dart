import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/theme.dart';

class CategoryPageLoader extends StatelessWidget {
  const CategoryPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width / 2) - 23;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.white),
                    child: const _CategoryTabSkeleton(),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ShimmerBuilder(
                    width: double.infinity,
                    height: 48,
                    radius: SharePerksRadii.md,
                  ),
                ),
                const SizedBox(width: 12),
                ShimmerBuilder(
                  width: 44,
                  height: 44,
                  radius: SharePerksRadii.md,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(8, (index) {
                return Container(
                  width: cardWidth,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neutral200.withAlpha(95),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: ShimmerBuilder(
                          radius: 0,
                          width: cardWidth,
                          height: 121,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBuilder(width: 120, height: 14, radius: 8),
                            SizedBox(height: 8),
                            ShimmerBuilder(width: 90, height: 10, radius: 6),
                            SizedBox(height: 10),
                            ShimmerBuilder(width: 130, height: 28, radius: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabSkeleton extends StatelessWidget {
  const _CategoryTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerBuilder(width: 75, height: 75, radius: 16),
          SizedBox(height: 8),
          ShimmerBuilder(width: 70, height: 12, radius: 6),
        ],
      ),
    );
  }
}
