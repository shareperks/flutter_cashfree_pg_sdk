import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/theme.dart';

class HomePageLoader extends StatelessWidget {
  const HomePageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SharePerksRadii.lg),
              child: ShimmerBuilder(radius: 0, width: width, height: 160),
            ),
          ),
          const SizedBox(height: SharePerksSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.white),
              child: _WelcomeCardSkeleton(),
            ),
          ),
          const SizedBox(height: SharePerksSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.white),
              child: _SectionSkeleton(
                titleWidth: 170,
                trailingWidth: 70,
                itemHeight: 220,
                itemWidth: 165,
                itemCount: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: _SectionHeaderSkeleton(titleWidth: 140, trailingWidth: 70),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Container(
                  width: 96,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neutral200.withAlpha(95),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBuilder(width: 50, height: 50, radius: 12),
                        SizedBox(height: 10),
                        ShimmerBuilder(width: 60, height: 12, radius: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SharePerksRadii.lg),
              child: ShimmerBuilder(radius: 0, width: width, height: 150),
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: _SectionHeaderSkeleton(titleWidth: 190, trailingWidth: 0),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return const _OptionChipSkeleton();
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: _FooterSkeleton()),
          ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }
}

class _WelcomeCardSkeleton extends StatelessWidget {
  const _WelcomeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ShimmerBuilder(width: 110, height: 16, radius: 8),
            const SizedBox(width: 10),
            const ShimmerBuilder(width: 80, height: 16, radius: 8),
          ],
        ),
        const SizedBox(height: 14),
        ShimmerBuilder(width: width, height: 70, radius: 16),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({
    required this.titleWidth,
    required this.trailingWidth,
    required this.itemHeight,
    required this.itemWidth,
    required this.itemCount,
  });

  final double titleWidth;
  final double trailingWidth;
  final double itemHeight;
  final double itemWidth;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderSkeleton(
          titleWidth: titleWidth,
          trailingWidth: trailingWidth,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: itemHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: itemWidth,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral200.withAlpha(95)),
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
                        width: itemWidth,
                        height: itemHeight * 0.55,
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
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton({
    required this.titleWidth,
    required this.trailingWidth,
  });

  final double titleWidth;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShimmerBuilder(width: titleWidth, height: 18, radius: 8),
        const Spacer(),
        if (trailingWidth > 0)
          ShimmerBuilder(width: trailingWidth, height: 14, radius: 8),
      ],
    );
  }
}

class _OptionChipSkeleton extends StatelessWidget {
  const _OptionChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerBuilder(width: 36, height: 36, radius: 10),
            SizedBox(height: 10),
            ShimmerBuilder(width: 70, height: 12, radius: 6),
          ],
        ),
      ),
    );
  }
}

class _FooterSkeleton extends StatelessWidget {
  const _FooterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ShimmerBuilder(width: 140, height: 12, radius: 6),
          SizedBox(height: 8),
          ShimmerBuilder(width: 220, height: 12, radius: 6),
        ],
      ),
    );
  }
}
