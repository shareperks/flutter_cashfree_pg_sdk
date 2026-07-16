import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/constants/onesignal_config.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';

/// Production OneSignal facade. Screens must not import `onesignal_flutter`.
///
/// Lifecycle:
/// 1. [init] once from `main()` (no permission prompt)
/// 2. [onUserSet] after auth / session restore → `OneSignal.login` + optional prompt
/// 3. [onUserCleared] on logout → `OneSignal.logout`
/// 4. [setOptedIn] from Settings notifications toggle
class OneSignalPush {
  OneSignalPush._();

  static const _permissionAskedKey = 'push_permission_asked_v1';

  static bool _initialized = false;

  /// Known deep-link route names (same set as in-app notification taps).
  static const knownRoutes = <String>{
    RouteNames.HOME_SCREEN,
    RouteNames.GIFTCARD_VIEW_SCREEN,
    RouteNames.CASHBACK_VIEW_SCREEN,
    RouteNames.PROMOCODE_VIEW_SCREEN,
    RouteNames.MY_WALLET_SCREEN,
    RouteNames.WALLET_HISTORY_SCREEN,
    RouteNames.EARNING_SCREEN,
    RouteNames.MY_REFER_LIST_SCREEN,
    RouteNames.REFER_CODE_SCREEN,
    RouteNames.CLAIMED_PERKS_SCREEN,
    RouteNames.MY_HOLDING_VIEW_SCREEN,
    RouteNames.PROFILE_EDIT_SCREEN,
    RouteNames.HELP_AND_SUPPORT_SCREEN,
    RouteNames.FAQS_SCREEN,
    RouteNames.SETTINGS_SCREEN,
    RouteNames.NOTIFICATION_SCREEN,
    // Listing screens (home carousel SCREEN slides + push deep-links)
    RouteNames.UNLOCKED_PERKS_SCREEN,
    RouteNames.GIFTCARD_PERK_SCREEN,
    RouteNames.PROMOOCODE_PERK_SCREEN,
    RouteNames.CASHBACK_PERK_SCREEN,
    RouteNames.TOP_PERKS_SCREEN,
    RouteNames.TOP_BRANDS_SCREEN,
  };

  /// Call once from `main()` after [LocalStorage.init], before `runApp`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (OneSignalConfig.enableVerboseLogs) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      OneSignal.initialize(OneSignalConfig.appId);

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
        unawaited(
          AnalyticsService.instance.track(AnalyticsEvent.pushReceived, {
            'campaign_id': event.notification.notificationId,
            if (event.notification.title != null)
              'title': event.notification.title!,
          }),
        );
      });

      OneSignal.Notifications.addClickListener((event) {
        final n = event.notification;
        unawaited(
          AnalyticsService.instance.track(AnalyticsEvent.pushOpened, {
            'campaign_id': n.notificationId,
            if (n.title != null) 'title': n.title!,
          }),
        );
        _handleNotificationOpened(n.additionalData);
      });
    } catch (e, st) {
      debugPrint('[onesignal] init failed: $e\n$st');
    }
  }

  /// Call when a logged-in user is set (OTP, splash restore, profile setup).
  static Future<void> onUserSet(String userId) async {
    if (userId.isEmpty) return;
    try {
      await OneSignal.login(userId);
      final subscriptionId = OneSignal.User.pushSubscription.id;
      unawaited(
        AnalyticsService.instance.track(AnalyticsEvent.pushTokenRegistered, {
          'external_user_id': userId,
          'subscription_id': ?subscriptionId,
        }),
      );
      await requestPermissionIfNeeded();
    } catch (e, st) {
      debugPrint('[onesignal] onUserSet failed: $e\n$st');
    }
  }

  /// Call on logout / session clear.
  static Future<void> onUserCleared() async {
    try {
      await OneSignal.logout();
    } catch (e, st) {
      debugPrint('[onesignal] onUserCleared failed: $e\n$st');
    }
  }

  /// Prompts once per install (after login). Safe to call repeatedly.
  /// Returns `true` if permission is granted (or already granted).
  static Future<bool> requestPermissionIfNeeded({
    bool force = false,
  }) async {
    try {
      final alreadyAsked =
          LocalStorage.getString(_permissionAskedKey) == '1';
      if (!force && alreadyAsked) {
        return OneSignal.Notifications.permission;
      }
      final granted =
          await OneSignal.Notifications.requestPermission(true);
      await LocalStorage.setString(_permissionAskedKey, '1');
      return granted;
    } catch (e, st) {
      debugPrint('[onesignal] requestPermission failed: $e\n$st');
      return false;
    }
  }

  static bool get isOptedIn =>
      OneSignal.User.pushSubscription.optedIn == true;

  static Future<void> setOptedIn(bool enabled) async {
    try {
      if (enabled) {
        await OneSignal.User.pushSubscription.optIn();
      } else {
        await OneSignal.User.pushSubscription.optOut();
      }
    } catch (e, st) {
      debugPrint('[onesignal] setOptedIn($enabled) failed: $e\n$st');
    }
  }

  static void _handleNotificationOpened(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return;

    final screen = data['screen']?.toString().trim();
    if (screen == null || screen.isEmpty) return;
    if (!knownRoutes.contains(screen)) {
      debugPrint('[onesignal] ignoring unknown deep-link screen: $screen');
      return;
    }

    final rewardId = data['rewardId']?.toString();
    final extra = (rewardId != null && rewardId.isNotEmpty)
        ? <String, dynamic>{'rewardId': rewardId}
        : null;

    // Delay slightly so the navigator is ready after cold-start from a tap.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      final ctx = GoRouterKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      try {
        ctx.pushNamed(screen, extra: extra);
      } catch (e) {
        debugPrint('[onesignal] deep-link navigation failed: $e');
      }
    });
  }
}
