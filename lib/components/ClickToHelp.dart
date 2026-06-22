import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

/// "Need help? Click here." footer used on holdings, claimed perks, etc.
///
/// Tapping anywhere on the row pushes [RouteNames.HELP_AND_SUPPORT_SCREEN]
/// — the same destination as the Settings / Wallet / Menu "Help & Support"
/// entries — so users get a single, consistent help experience regardless
/// of where they enter from.
class ClickToHelp extends StatelessWidget {
  const ClickToHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(RouteNames.HELP_AND_SUPPORT_SCREEN),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 4,
          children: [
            Text(
              'Need help?',
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'Click here.',
              style: TextStyle(
                color: SharePerksColors.accent,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationColor: SharePerksColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
