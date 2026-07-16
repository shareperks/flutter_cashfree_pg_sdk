import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/home_common_models.dart';

/// Carousel slide navigation: reward detail vs listing screen.
class HomeSlideNavigation {
  HomeSlideNavigation._();

  /// Mirrors admin slides catalog (`screens.ts`) and [RouteNames].
  static const allowedScreenRoutes = <String>{
    RouteNames.UNLOCKED_PERKS_SCREEN,
    RouteNames.GIFTCARD_PERK_SCREEN,
    RouteNames.PROMOOCODE_PERK_SCREEN,
    RouteNames.CASHBACK_PERK_SCREEN,
    RouteNames.TOP_PERKS_SCREEN,
    RouteNames.TOP_BRANDS_SCREEN,
  };

  static bool isAllowedScreenRoute(String route) =>
      allowedScreenRoutes.contains(route.trim());

  /// Whether the slide should respond to taps (includes screen allowlist).
  static bool isTappable(HomeSlide slide) {
    if (slide.canNavigateToReward) return true;
    if (!slide.canNavigateToScreen) return false;
    return isAllowedScreenRoute(slide.screenRoute!);
  }
}

/// Navigate from a home carousel slide: [SCREEN] listing or [REWARD] detail.
void navigateHomeSlide(
  HomeSlide slide, {
  required String source,
  int? position,
}) {
  if (slide.canNavigateToScreen) {
    final route = slide.screenRoute!.trim();
    if (!HomeSlideNavigation.isAllowedScreenRoute(route)) {
      debugPrint(
        '[home_slide] unknown screenRoute="$route" id=${slide.id}',
      );
      return;
    }

    trackAction(AnalyticsEvent.perkCardClicked, {
      'source': source,
      'redirect_kind': 'SCREEN',
      'screen_route': route,
      'position': ?position,
      'slide_id': ?slide.id,
    });

    GoRouterKey.currentContext?.pushNamed(route);
    return;
  }

  if (slide.canNavigateToReward) {
    navigateRewardScreen(
      slide.rewardTypeNormalized!,
      slide.rewardId!,
      source: source,
      position: position,
      redirectKind: 'REWARD',
    );
    return;
  }

  debugPrint(
    '[home_slide] untappable slide id=${slide.id} '
    'kind=${slide.redirectKind} route=${slide.screenRoute} '
    'rewardType=${slide.type} rewardId=${slide.rewardId}',
  );
}
