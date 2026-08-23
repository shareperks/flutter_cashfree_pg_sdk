import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ShimmerBuilder.dart';

/// Placeholder for the company details screen while the page bundle loads —
/// a cold request can take a couple of seconds.
class CompanyDetailsLoader extends StatelessWidget {
  const CompanyDetailsLoader({super.key});

  Widget _card(double height) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SharePerksSpacing.md),
      child: ShimmerBuilder(
        width: double.infinity,
        height: height,
        radius: SharePerksRadii.lg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(SharePerksSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBuilder(width: 180, height: 22, radius: 8),
          const SizedBox(height: 10),
          ShimmerBuilder(width: width * 0.5, height: 14, radius: 6),
          const SizedBox(height: SharePerksSpacing.md),
          _card(150),
          _card(190),
          _card(220),
          _card(200),
        ],
      ),
    );
  }
}
