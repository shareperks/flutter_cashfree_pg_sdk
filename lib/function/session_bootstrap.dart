import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';

/// Verifies the stored session, hydrates [UserProvider], and navigates to the
/// correct post-splash destination.
///
/// Used by [SplashScreen] and the optional-update "Not now" path so profile
/// data is always loaded before Home.
Future<void> bootstrapLoggedInSession(BuildContext context) async {
  final isLoggedIn = await AuthService.isLoggedIn();
  if (!context.mounted) return;

  if (!isLoggedIn) {
    context.read<UserProvider>().clearUser();
    context.goNamed(RouteNames.LANDING_SCREEN);
    return;
  }

  final session = await AuthService.verifySession();
  if (!context.mounted) return;

  if (session.success != true || session.user == null) {
    await AuthService.logout();
    if (!context.mounted) return;
    context.read<UserProvider>().clearUser();
    context.goNamed(RouteNames.LANDING_SCREEN);
    return;
  }

  final user = session.user!;
  context.read<UserProvider>().setUser(user);
  await LocalStorage.setString('userId', user.id ?? '');

  if (user.id != null) {
    await AnalyticsService.instance.identify(user.id!, {
      if (user.mobile != null) 'mobile': user.mobile,
      'restored_session': true,
    });
  }

  if (!context.mounted) return;

  if (user.isActive != true) {
    await AuthService.logout();
    if (!context.mounted) return;
    Fluttertoast.showToast(
      msg: 'Your account is not active. Please contact support.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    context.read<UserProvider>().clearUser();
    context.goNamed(RouteNames.LANDING_SCREEN);
    return;
  }

  if (user.name == null || user.email == null) {
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
}
