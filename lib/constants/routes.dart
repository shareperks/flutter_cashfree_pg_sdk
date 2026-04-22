import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/common/NewUpdate_screen.dart';
import 'package:shareperks/common/NoInternet_screen.dart';
import 'package:shareperks/common/NotFound_screen.dart';
import 'package:shareperks/common/Splash_screen.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/function/initCheck.dart';
import 'package:shareperks/screens/info/HowShowPerkScreen.dart';
import 'package:shareperks/screens/info/InfoSlideScreen.dart';
import 'package:shareperks/screens/info/LinkDematInfoScreen.dart';
import 'package:shareperks/screens/landing/LandingScreen.dart';
import 'package:shareperks/screens/landing/LoginScreen.dart';
import 'package:shareperks/screens/landing/OtpScreen.dart';
import 'package:shareperks/screens/landing/ProfileSuccessScreen.dart';
import 'package:shareperks/screens/landing/SetupScreen.dart';
import 'package:shareperks/screens/main/CategotyScreen.dart';
import 'package:shareperks/screens/main/HomeScreen.dart';

// Routes names
class RouteNames {
  static const String SPLASH = 'SplashScreen';
  static const String LANDING_SCREEN = 'LandingScreen';
  static const String NO_INTERNET = 'NoInternetScreen';
  static const String NEW_UPDATE = 'NewUpdateScreen';
  static const String LOGIN_SCREEN = 'LoginScreen';
  static const String OTP_SCREEN = 'OtpScreen';
  static const String SETUP_SCREEN = 'SetupScreen';
  static const String PROFILE_SUCCESS_SCREEN = 'ProfileSuccessScreen';
  static const String HOW_SHOW_PERK_SCREEN = 'HowShowPerkScreen';
  static const String LINK_DEMAT_INFO_SCREEN = 'LinkDematInfoScreen';
  static const String INFO_SLIDE_SCREEN = 'InfoSlideScreen';
  static const String HOME_SCREEN = 'HomeScreen';
  static const String CATEGORY_SCREEN = 'CategoryScreen';
  static String path(String route) =>
      "/${route.toLowerCase().replaceAll(" ", "_")}";
}

// Routes configuration
final List<GoRoute> routes = [
  GoRoute(
    name: RouteNames.SPLASH,
    path: RouteNames.path(RouteNames.SPLASH),
    builder: (BuildContext context, GoRouterState state) => SplashScreen(),
  ),

  GoRoute(
    name: RouteNames.LANDING_SCREEN,
    path: RouteNames.path(RouteNames.LANDING_SCREEN),
    builder: (BuildContext context, GoRouterState state) => LandingScreen(),
  ),

  GoRoute(
    name: RouteNames.LOGIN_SCREEN,
    path: RouteNames.path(RouteNames.LOGIN_SCREEN),
    builder: (BuildContext context, GoRouterState state) => LoginScreen(),
  ),

  GoRoute(
    name: RouteNames.OTP_SCREEN,
    path: RouteNames.path(RouteNames.OTP_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      final phone = state.extra as Map<String, dynamic>;
      return OtpScreen(phone: phone['phone'] as String);
    },
  ),
  GoRoute(
    name: RouteNames.SETUP_SCREEN,
    path: RouteNames.path(RouteNames.SETUP_SCREEN),
    builder: (BuildContext context, GoRouterState state) => SetupScreen(),
  ),
  GoRoute(
    name: RouteNames.PROFILE_SUCCESS_SCREEN,
    path: RouteNames.path(RouteNames.PROFILE_SUCCESS_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        ProfileSuccessScreen(),
  ),
  GoRoute(
    name: RouteNames.HOW_SHOW_PERK_SCREEN,
    path: RouteNames.path(RouteNames.HOW_SHOW_PERK_SCREEN),
    builder: (BuildContext context, GoRouterState state) => HowShowPerkScreen(),
  ),
  GoRoute(
    name: RouteNames.LINK_DEMAT_INFO_SCREEN,
    path: RouteNames.path(RouteNames.LINK_DEMAT_INFO_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        LinkDematInfoScreen(),
  ),
  GoRoute(
    name: RouteNames.INFO_SLIDE_SCREEN,
    path: RouteNames.path(RouteNames.INFO_SLIDE_SCREEN),
    builder: (BuildContext context, GoRouterState state) => InfoSlideScreen(),
  ),
  GoRoute(
    name: RouteNames.HOME_SCREEN,
    path: RouteNames.path(RouteNames.HOME_SCREEN),
    builder: (BuildContext context, GoRouterState state) => HomeScreen(),
  ),
  GoRoute(
    name: RouteNames.CATEGORY_SCREEN,
    path: RouteNames.path(RouteNames.CATEGORY_SCREEN),
    builder: (BuildContext context, GoRouterState state) => CategoryScreen(),
  ),
  GoRoute(
    name: RouteNames.NO_INTERNET,
    path: RouteNames.path(RouteNames.NO_INTERNET),
    builder: (BuildContext context, GoRouterState state) => NoInternetScreen(
      onRetry: () {
        context.goNamed(RouteNames.SPLASH, extra: state.extra);
      },
    ),
  ),
  GoRoute(
    name: RouteNames.NEW_UPDATE,
    path: RouteNames.path(RouteNames.NEW_UPDATE),
    builder: (BuildContext context, GoRouterState state) {
      final extra = state.extra as Map<String, dynamic>;
      return NewUpdateScreen(
        title: extra['title'] as String,
        message: extra['message'] as String,
        isForceUpdate: extra['isForceUpdate'] as bool,
      );
    },
  ),
];

List<String> offlineRoutes = [
  RouteNames.SPLASH,
  RouteNames.NO_INTERNET,
  RouteNames.NEW_UPDATE,
];

/// Logs whenever the user pops the top route (system back, `pop`, etc.).
final class StarvestRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final from = _routeLabel(route);
    final to = previousRoute != null ? _routeLabel(previousRoute) : '(root)';
    print('$to <- $from');
  }

  String _routeLabel(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.runtimeType.toString();
  }
}

// GoRouter configuration
final GoRouter router = GoRouter(
  initialLocation: RouteNames.path(RouteNames.SPLASH),
  routes: routes,
  navigatorKey: GoRouterKey,
  observers: [StarvestRouteObserver()],
  onEnter: (context, currentState, nextState, goRouter) async {
    print('${currentState.name} -> ${nextState.name}');
    final path = nextState.uri.path;
    final name = nextState.name;
    bool isOfflineRoute =
        offlineRoutes.contains(name) || offlineRoutes.contains(path);

    // Splash decides where to go after its delay — don't intercept initial load.
    if (isOfflineRoute) {
      return const Allow();
    }

    final online = await checkInternetConnection();
    if (!online && !isOfflineRoute) {
      return Block.then(() => goRouter.goNamed(RouteNames.NO_INTERNET));
    }
    return const Allow();
  },
  debugLogDiagnostics: true,
  errorBuilder: (BuildContext context, GoRouterState state) {
    return NotFoundScreen();
  },
);
