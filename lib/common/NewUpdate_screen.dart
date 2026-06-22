import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';
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
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(AnalyticsEvent.forceUpdateShown, {
      'is_force_update': widget.isForceUpdate,
    });
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
                    onPressed: () {
                      // check platform
                      if (Platform.isAndroid) {
                        // open play store
                        launchUrl(
                          Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.shareperks',
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      } else if (Platform.isIOS) {
                        // open app store
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
                    onPressed: () async {
                      final isLoggedIn = await AuthService.isLoggedIn();
                      if (isLoggedIn) {
                        context.goNamed(RouteNames.HOME_SCREEN);
                      } else {
                        context.goNamed(RouteNames.LOGIN_SCREEN);
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
