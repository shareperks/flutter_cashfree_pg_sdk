import 'package:flutter/material.dart';

import 'analytics_service.dart';
import 'journey_context.dart';
import 'screen_session.dart';

/// Drop-in replacement for the global `routeObserver` in
/// `lib/utils/navigation.dart`. It still serves as the `RouteObserver` the
/// existing `RouteAwareTrackingMixin` subscribes to, AND it auto-emits
/// `screen_view` / `screen_exit` analytics events for navigation changes.
///
/// Migration: change `lib/utils/navigation.dart` to
///
///   final AnalyticsRouteObserver<PageRoute<dynamic>> routeObserver =
///       AnalyticsRouteObserver<PageRoute<dynamic>>();
///
/// Existing screens that use `RouteAwareTrackingMixin` keep working unchanged
/// because [AnalyticsRouteObserver] extends [RouteObserver].
///
/// Disable duplicate `screen_view` emission from `RouteAwareTrackingMixin`
/// once this observer is live.
class AnalyticsRouteObserver<R extends PageRoute<dynamic>> extends RouteObserver<R> {
  String _label(Route<dynamic>? route) {
    if (route == null) return '<unknown>';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.runtimeType.toString();
  }

  void _emitEnter(Route<dynamic>? current, Route<dynamic>? previous) {
    final name = _label(current);
    if (name == '<unknown>') return;

    JourneyContext.currentScreen = name;
    JourneyContext.screenEnteredAt = DateTime.now();

    // Opens the CRM "card" for this visit; closed (and emitted) on exit.
    ScreenSession.begin(name);

    AnalyticsService.instance.screen(name, {
      if (previous != null) 'previous_screen': _label(previous),
      ...JourneyContext.baseProps(),
    });
  }

  /// Closes the current visit, emitting a `screen_session` card with the
  /// screen name, entity name, time range and the ordered clicks.
  void _emitExit(Route<dynamic> route) {
    if (_label(route) == '<unknown>') return;
    ScreenSession.end();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! R) {
      super.didPush(route, previousRoute);
      return;
    }
    if (previousRoute is R) {
      _emitExit(previousRoute);
    }
    super.didPush(route, previousRoute);
    _emitEnter(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is! R) {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      return;
    }
    if (oldRoute is R) {
      _emitExit(oldRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _emitEnter(newRoute, oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! R) {
      super.didPop(route, previousRoute);
      return;
    }
    _emitExit(route);
    super.didPop(route, previousRoute);
    if (previousRoute is R) {
      _emitEnter(previousRoute, route);
    }
  }
}
