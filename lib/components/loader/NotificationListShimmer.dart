import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton list for [NotificationsScreen] while the first page loads.
class NotificationListShimmer extends StatelessWidget {
  const NotificationListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _NotificationShimmerCard(),
        ),
      ),
    );
  }
}

class _NotificationShimmerCard extends StatelessWidget {
  const _NotificationShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBuilder(width: 72, height: 18, radius: 9),
          const SizedBox(height: 10),
          ShimmerBuilder(width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 6),
          ShimmerBuilder(width: 180, height: 12, radius: 6),
          const SizedBox(height: 10),
          ShimmerBuilder(width: 96, height: 10, radius: 5),
        ],
      ),
    );
  }
}
