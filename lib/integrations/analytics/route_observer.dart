import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// Drop-in replacement for the global `routeObserver` in
/// `lib/utils/navigation.dart`. It still serves as the `RouteObserver` the
/// existing `RouteAwareTrackingMixin` subscribes to, AND it auto-emits a
/// `screen_view` analytics event for every `didPush` / `didReplace` /
/// `didPopNext`.
///
/// Migration: change `lib/utils/navigation.dart` to
///
///   final AnalyticsRouteObserver<PageRoute<dynamic>> routeObserver =
///       AnalyticsRouteObserver<PageRoute<dynamic>>();
///
/// Existing screens that use `RouteAwareTrackingMixin` keep working unchanged
/// because [AnalyticsRouteObserver] extends [RouteObserver].
class AnalyticsRouteObserver<R extends PageRoute<dynamic>> extends RouteObserver<R> {
  String _label(Route<dynamic>? route) {
    if (route == null) return '<unknown>';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    // Default: runtime type of the widget the PageRoute is hosting.
    final type = route.runtimeType.toString();
    return type;
  }

  void _emit(Route<dynamic>? current, Route<dynamic>? previous) {
    final name = _label(current);
    if (name == '<unknown>') return;
    AnalyticsService.instance.screen(name, {
      if (previous != null) 'previous_screen': _label(previous),
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _emit(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _emit(newRoute, oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // User navigated back; the previous route is now the visible screen.
    _emit(previousRoute, route);
  }
}
