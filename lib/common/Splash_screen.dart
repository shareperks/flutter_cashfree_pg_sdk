import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/initCheck.dart';

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
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final online = await checkInternetConnection();
    if (!mounted) return;
    if (online) {
      context.goNamed(RouteNames.LANDING_SCREEN);
    } else {
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
            // hide for 2 sec slide up with fade in
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
