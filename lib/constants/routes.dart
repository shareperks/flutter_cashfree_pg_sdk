import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/common/NewUpdate_screen.dart';
import 'package:shareperks/common/NoInternet_screen.dart';
import 'package:shareperks/common/NotFound_screen.dart';
import 'package:shareperks/common/Splash_screen.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/function/initCheck.dart';
import 'package:shareperks/screens/forms/RequestPerkScreen.dart';
import 'package:shareperks/screens/holding/ListBrokersScreen.dart';
import 'package:shareperks/screens/holding/MyHoldingScreen.dart';
import 'package:shareperks/screens/holding/UploadHoldingStatementScreen.dart';
import 'package:shareperks/screens/info/FaqsScreen.dart';
import 'package:shareperks/screens/info/HelpAndSupportScreen.dart';
import 'package:shareperks/screens/info/HowShowPerkScreen.dart';
import 'package:shareperks/screens/info/InfoSlideScreen.dart';
import 'package:shareperks/screens/info/LinkDematInfoScreen.dart';
import 'package:shareperks/screens/landing/LandingScreen.dart';
import 'package:shareperks/screens/landing/LoginScreen.dart';
import 'package:shareperks/screens/landing/OtpScreen.dart';
import 'package:shareperks/screens/landing/ProfileSuccessScreen.dart';
import 'package:shareperks/screens/landing/SetupScreen.dart';
import 'package:shareperks/screens/main/BrandViewScreen.dart';
import 'package:shareperks/screens/main/CategotyScreen.dart';
import 'package:shareperks/screens/main/CompanyViewScreen.dart';
import 'package:shareperks/screens/main/HomeScreen.dart';
import 'package:shareperks/screens/main/MenuListScreen.dart';
import 'package:shareperks/screens/main/NotifIcationsScreen.dart';
import 'package:shareperks/screens/main/TopBrandsScreen.dart';
import 'package:shareperks/screens/main/TopPerksScreen.dart';
import 'package:shareperks/screens/main/TypePerkSceen.dart';
import 'package:shareperks/screens/main/UnlockedPerksScreen%20copy.dart';
import 'package:shareperks/screens/rewards/GiftCardRewardScreen.dart';

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
  static const String UNLOCKED_PERKS_SCREEN = 'UnlockedPerksScreen';
  static const String TOP_PERKS_SCREEN = 'TopPerksScreen';
  static const String CASHBACK_PERK_SCREEN = 'CashBackPerkScreen';
  static const String GIFTCARD_PERK_SCREEN = 'GiftCardPerkScreen';
  static const String PROMOOCODE_PERK_SCREEN = 'PromoCodePerkScreen';
  static const String TOP_BRANDS_SCREEN = 'TopBrandScreen';
  static const String BRAND_SCREEN = 'BrandScreen';
  static const String COMPANY_SCREEN = 'CompanyScreen';
  static const String MENU_SCREEN = 'MenuScreen';
  static const String HELP_AND_SUPPORT_SCREEN = 'HelpAndSupportScreen';
  static const String FAQS_SCREEN = 'FAQsScreen';
  static const String NOTIFICATION_SCREEN = 'NotificationScreen';
  static const String REQUEST_PERK_SCREEN = 'RequestPerkScreen';
  static const String GIFTCARD_VIEW_SCREEN = 'GiftCardViewScreen';
  static const String MY_HOLDING_VIEW_SCREEN = 'MyHoldingViewScreen';
  static const String LIST_BROKER_VIEW_SCREEN = 'ListBrokerViewScreen';
  static const String UPLOAD_HOLDING_SCREEN = 'UploadHoldingScreen';

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
    name: RouteNames.HELP_AND_SUPPORT_SCREEN,
    path: RouteNames.path(RouteNames.HELP_AND_SUPPORT_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        HelpAndSupportScreen(),
  ),
  GoRoute(
    name: RouteNames.FAQS_SCREEN,
    path: RouteNames.path(RouteNames.FAQS_SCREEN),
    builder: (BuildContext context, GoRouterState state) => FAQsScreen(),
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
    name: RouteNames.UNLOCKED_PERKS_SCREEN,
    path: RouteNames.path(RouteNames.UNLOCKED_PERKS_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        UnlockedPerksScreen(),
  ),
  GoRoute(
    name: RouteNames.NOTIFICATION_SCREEN,
    path: RouteNames.path(RouteNames.NOTIFICATION_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        NotificationsScreen(),
  ),
  GoRoute(
    name: RouteNames.TOP_PERKS_SCREEN,
    path: RouteNames.path(RouteNames.TOP_PERKS_SCREEN),
    builder: (BuildContext context, GoRouterState state) => TopPerksScreen(),
  ),
  GoRoute(
    name: RouteNames.CASHBACK_PERK_SCREEN,
    path: RouteNames.path(RouteNames.CASHBACK_PERK_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        TypePerkScreen(type: "cashback"),
  ),
  GoRoute(
    name: RouteNames.GIFTCARD_PERK_SCREEN,
    path: RouteNames.path(RouteNames.GIFTCARD_PERK_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        TypePerkScreen(type: "giftcard"),
  ),
  GoRoute(
    name: RouteNames.PROMOOCODE_PERK_SCREEN,
    path: RouteNames.path(RouteNames.PROMOOCODE_PERK_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        TypePerkScreen(type: "promocode"),
  ),
  GoRoute(
    name: RouteNames.CATEGORY_SCREEN,
    path: RouteNames.path(RouteNames.CATEGORY_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      final extra = state.extra;
      final String? categoryId = extra is Map<String, dynamic>
          ? extra['categoryId'] as String?
          : null;
      return CategoryScreen(categoryId: categoryId);
    },
  ),
  GoRoute(
    name: RouteNames.TOP_BRANDS_SCREEN,
    path: RouteNames.path(RouteNames.TOP_BRANDS_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      return TopBrandsScreen();
    },
  ),
  GoRoute(
    name: RouteNames.BRAND_SCREEN,
    path: RouteNames.path(RouteNames.BRAND_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      final extra = state.extra;
      final String? brandId = extra is Map<String, dynamic>
          ? extra['brandId'] as String?
          : null;
      return BrandViewScreen(brandId: brandId!);
    },
  ),
  GoRoute(
    name: RouteNames.COMPANY_SCREEN,
    path: RouteNames.path(RouteNames.COMPANY_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      final extra = state.extra;
      final String? companyId = extra is Map<String, dynamic>
          ? extra['companyId'] as String?
          : null;
      return CompanyViewScreen(companyId: companyId!);
    },
  ),
  GoRoute(
    name: RouteNames.GIFTCARD_VIEW_SCREEN,
    path: RouteNames.path(RouteNames.GIFTCARD_VIEW_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      final extra = state.extra;
      final String? rewardId = extra is Map<String, dynamic>
          ? extra['rewardId'] as String?
          : null;
      return GiftCardRewardScreen(rewardId: rewardId!);
    },
  ),
  GoRoute(
    name: RouteNames.MENU_SCREEN,
    path: RouteNames.path(RouteNames.MENU_SCREEN),
    builder: (BuildContext context, GoRouterState state) {
      return MenuListScreen();
    },
  ),

  GoRoute(
    name: RouteNames.REQUEST_PERK_SCREEN,
    path: RouteNames.path(RouteNames.REQUEST_PERK_SCREEN),
    builder: (BuildContext context, GoRouterState state) => RequestPerkScreen(),
  ),
  GoRoute(
    name: RouteNames.MY_HOLDING_VIEW_SCREEN,
    path: RouteNames.path(RouteNames.MY_HOLDING_VIEW_SCREEN),
    builder: (BuildContext context, GoRouterState state) => MyHoldingScreen(),
  ),
  GoRoute(
    name: RouteNames.LIST_BROKER_VIEW_SCREEN,
    path: RouteNames.path(RouteNames.LIST_BROKER_VIEW_SCREEN),
    builder: (BuildContext context, GoRouterState state) => ListBrokerScreen(),
  ),
  GoRoute(
    name: RouteNames.UPLOAD_HOLDING_SCREEN,
    path: RouteNames.path(RouteNames.UPLOAD_HOLDING_SCREEN),
    builder: (BuildContext context, GoRouterState state) =>
        UploadHoldingStatementScreen(),
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
