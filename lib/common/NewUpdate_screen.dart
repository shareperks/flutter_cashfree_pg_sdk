import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Full-screen prompt when a newer app version is available.
class NewUpdateScreen extends StatelessWidget {
  const NewUpdateScreen({super.key, this.onUpdate, this.onLater});

  /// Opens store / in-app update. No-op if null.
  final VoidCallback? onUpdate;

  /// Dismisses the prompt. Defaults to [Navigator.maybePop] if null.
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            Assets.ASSETS_LOTTIE_ROCKERT_JSON,
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
            repeat: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: Column(
              children: [
                Text(
                  'New update available',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SharePerksSpacing.sm),
                Text(
                  'A newer version of StarVest is ready. Update for the latest features and fixes.',
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
                    onPressed: onUpdate ?? () {},
                    icon: const Icon(Icons.system_update_alt_rounded, size: 22),
                    label: const Text('Update now'),
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
                    if (onLater != null) {
                      onLater!();
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
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
