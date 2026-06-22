import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/repository/services/auth/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? user;

  void setUser(UserModel user) {
    this.user = user;
    notifyListeners();
  }

  void clearUser() {
    final hadUser = user != null;
    user = null;
    notifyListeners();
    // Centralised analytics teardown for every logout site (Splash retry path,
    // future Settings → Logout, etc.). Best-effort: never throw.
    if (hadUser) {
      unawaited(AnalyticsService.instance.track(AnalyticsEvent.logout));
    }
    unawaited(AnalyticsService.instance.reset());
  }
}
