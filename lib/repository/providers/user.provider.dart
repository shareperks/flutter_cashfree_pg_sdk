import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/onesignal_push.dart';
import 'package:shareperks/repository/services/auth/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? user;

  void setUser(UserModel user) {
    this.user = user;
    notifyListeners();
    final id = user.id;
    if (id != null && id.isNotEmpty) {
      unawaited(OneSignalPush.onUserSet(id));
    }
  }

  void clearUser() {
    final hadUser = user != null;
    user = null;
    notifyListeners();
    // Tear down push identity before analytics reset.
    unawaited(OneSignalPush.onUserCleared());
    // Centralised analytics teardown for every logout site (Splash retry path,
    // menu Logout, etc.). Best-effort: never throw.
    if (hadUser) {
      unawaited(AnalyticsService.instance.track(AnalyticsEvent.logout));
    }
    unawaited(AnalyticsService.instance.reset());
  }
}
