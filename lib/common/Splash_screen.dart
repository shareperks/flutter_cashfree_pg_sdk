import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/initCheck.dart';
import 'package:shareperks/function/session_bootstrap.dart';
import 'package:shareperks/function/tracking_bootstrap.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String version = '';

  @override
  void initState() {
    super.initState();
    getPackageInfo().then((value) {
      setState(() {
        version = value['version'];
      });
    });
    _goNextAfterSplash();
  }

  Future<void> _goNextAfterSplash() async {
    final tracking = bootstrapTracking();
    await Future<void>.delayed(const Duration(seconds: 2));
    await tracking;
    if (!mounted) return;
    final online = await checkInternetConnection();
    if (!mounted) return;
    if (online) {
      final version = await AuthService.getVersion();
      if (!mounted) return;
      if (version.isUpdateAvailable == true) {
        context.goNamed(
          RouteNames.NEW_UPDATE,
          extra: {
            'title': version.title,
            'message': version.message,
            'isForceUpdate': version.isForceUpdate,
          },
        );
        return;
      }
      await bootstrapLoggedInSession(context);
    } else if (mounted) {
      context.goNamed(RouteNames.NO_INTERNET);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            SvgPicture.asset(
              Assets.ASSETS_SPLASH_LOGO_SVG,
              width: 220,
              fit: BoxFit.contain,
            ).animate().fadeIn(duration: 2000.milliseconds),
            SvgPicture.asset(
                  Assets.ASSETS_SPLASH_TEXT_SVG,
                  width: 200,
                  fit: BoxFit.contain,
                )
                .animate()
                .fadeIn(duration: 1000.milliseconds, delay: 800.milliseconds)
                .slideY(begin: 2, end: 0, duration: 500.milliseconds),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Text(
                'V $version',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
