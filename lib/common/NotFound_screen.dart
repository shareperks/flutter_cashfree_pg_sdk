import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Full-screen 404-style state when a route or resource does not exist.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.onGoHome, this.onGoBack});

  /// Navigate to app home. No-op if null.
  final VoidCallback? onGoHome;

  /// Usually [Navigator.pop]. Defaults to [Navigator.maybePop] if null.
  final VoidCallback? onGoBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            Assets.ASSETS_LOTTIE_PANDA_JSON,
            width: MediaQuery.of(context).size.width * 0.6,
            fit: BoxFit.contain,
            repeat: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: Column(
              spacing: 10,
              children: [
                const SizedBox(height: SharePerksSpacing.xl),
                Text(
                  'Page not found',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'We cannot find that screen. It may have been moved or the link is wrong.',
                  style: text.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SharePerksSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onGoHome ?? () {},
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: const Text('Go To Home'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SharePerksColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: SharePerksSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SharePerksRadii.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SharePerksSpacing.sm),
                TextButton(
                  onPressed: () {
                    if (onGoBack != null) {
                      onGoBack!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SharePerksColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: SharePerksSpacing.sm,
                    ),
                  ),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
