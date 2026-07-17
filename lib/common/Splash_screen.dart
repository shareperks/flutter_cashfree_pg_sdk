import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/initCheck.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';

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

  Future getLoginUserData() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    print('isLoggedIn: $isLoggedIn');
    if (isLoggedIn) {
      final user = await AuthService.verifySession();
      if (user.success == true) {
        context.read<UserProvider>().setUser(user.user!);
        await LocalStorage.setString("userId", user.user?.id ?? "");
        if (user.user?.id != null) {
          await AnalyticsService.instance.identify(user.user!.id!, {
            if (user.user!.mobile != null) 'mobile': user.user!.mobile,
            'restored_session': true,
          });
        }
        if (user.user?.isActive != true) {
          await AuthService.logout();
          Fluttertoast.showToast(
            msg: 'Your account is not active. Please contact support.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          await AuthService.logout();
          context.read<UserProvider>().clearUser();
          context.goNamed(RouteNames.LANDING_SCREEN);
          return;
        }
        if (user.user?.name == null || user.user?.email == null) {
          Fluttertoast.showToast(
            msg: 'Please complete your profile to continue.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          context.read<UserProvider>().clearUser();
          context.goNamed(RouteNames.SETUP_SCREEN);
          return;
        }

        context.goNamed(RouteNames.HOME_SCREEN);
      } else {
        await AuthService.logout();
        context.read<UserProvider>().clearUser();
        context.goNamed(RouteNames.LANDING_SCREEN);
        return;
      }
    } else {
      context.read<UserProvider>().clearUser();
      context.goNamed(RouteNames.LANDING_SCREEN);
      return;
    }
  }

  Future<void> _goNextAfterSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final online = await checkInternetConnection();
    if (!mounted) return;
    if (online) {
      final version = await AuthService.getVersion();
      if (version.isUpdateAvailable == true) {
        context.goNamed(
          RouteNames.NEW_UPDATE,
          extra: {
            "title": version.title,
            "message": version.message,
            "isForceUpdate": version.isForceUpdate,
          },
        );
        return;
      } else {
        await getLoginUserData();
      }
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
