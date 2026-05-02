import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Skeleton for [SettingsScreen] while settings load from the API.
class SettingsScreenShimmer extends StatelessWidget {
  const SettingsScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 36;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBuilder(width: w * 0.52, height: 22, radius: 8),
        const SizedBox(height: 14),
        _SwitchRowShimmer(width: w),
        _SwitchRowShimmer(width: w),
        const SizedBox(height: 28),
        ShimmerBuilder(width: w * 0.45, height: 22, radius: 8),
        const SizedBox(height: 14),
        _SwitchRowShimmer(width: w),
        const SizedBox(height: 32),
        ShimmerBuilder(width: w, height: 120, radius: 16),
      ],
    );
  }
}

class _SwitchRowShimmer extends StatelessWidget {
  const _SwitchRowShimmer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 0, color: SharePerksColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Row(
        children: [
          ShimmerBuilder(width: width * 0.5, height: 14, radius: 7),
          const Spacer(),
          ShimmerBuilder(width: 48, height: 28, radius: 14),
        ],
      ),
    );
  }
}
