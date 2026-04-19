import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Full-screen offline state with Lottie, clear hierarchy, and themed actions.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, this.onRetry, this.onContactSupport});

  /// Defaults to [Navigator.pop] if null.
  final VoidCallback? onRetry;

  /// Defaults to [Navigator.pop] if null.
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 150),
          Lottie.asset(
            Assets.ASSETS_LOTTIE_NOINTERNET_JSON,
            width: 200,

            fit: BoxFit.contain,
            repeat: true,
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                const SizedBox(height: SharePerksSpacing.xl),
                Text(
                  'No internet connection',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SharePerksSpacing.sm),
                Text(
                  'Check your Wi‑Fi or mobile data, then try again.',
                  style: text.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SharePerksSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (onRetry != null) {
                        onRetry!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: const Text('Retry'),
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
                    if (onContactSupport != null) {
                      onContactSupport!();
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
                  child: const Text('Contact support'),
                ),
              ],
            ),
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }
}
