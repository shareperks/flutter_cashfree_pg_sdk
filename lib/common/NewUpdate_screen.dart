import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/function/session_bootstrap.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen prompt when a newer app version is available.
class NewUpdateScreen extends StatefulWidget {
  final String title;
  final String message;
  final bool isForceUpdate;
  const NewUpdateScreen({
    super.key,
    required this.title,
    required this.message,
    required this.isForceUpdate,
  });

  @override
  State<NewUpdateScreen> createState() => _NewUpdateScreenState();
}

class _NewUpdateScreenState extends State<NewUpdateScreen> {
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(AnalyticsEvent.forceUpdateShown, {
      'is_force_update': widget.isForceUpdate,
    });
  }

  Future<void> _onNotNow() async {
    if (_continuing) return;
    setState(() => _continuing = true);
    try {
      // Same session restore as splash — profile must be loaded before Home.
      await bootstrapLoggedInSession(context);
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

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
                  widget.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SharePerksSpacing.sm),
                Text(
                  widget.message,
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
                    onPressed: _continuing
                        ? null
                        : () {
                            if (Platform.isAndroid) {
                              launchUrl(
                                Uri.parse(
                                  'https://play.google.com/store/apps/details?id=com.shareperks',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            } else if (Platform.isIOS) {
                              launchUrl(
                                Uri.parse(
                                  'https://apps.apple.com/in/app/shareperks/id6746847398',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
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
                if (!widget.isForceUpdate)
                  TextButton(
                    onPressed: _continuing ? null : _onNotNow,
                    style: TextButton.styleFrom(
                      foregroundColor: SharePerksColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: SharePerksSpacing.sm,
                      ),
                    ),
                    child: _continuing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Not now'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
