import 'package:flutter/material.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';

class HomeDataProvider extends ChangeNotifier {
  HomeDataModel? homeData;

  /// Monotonically-increasing counter bumped whenever something happens
  /// outside of `HomeScreen` that should invalidate its data (e.g. the user
  /// switches their primary demat account, disconnects a broker, etc.).
  ///
  /// `HomeScreen` snapshots this in `initState`, listens for changes, and
  /// re-fetches whenever it observes a higher value.
  int reloadVersion = 0;

  void setHomeData(HomeDataModel? homeData) {
    this.homeData = homeData;
    notifyListeners();
  }

  /// Ask any mounted `HomeScreen` to re-fetch its data on next opportunity.
  void requestReload() {
    reloadVersion++;
    notifyListeners();
  }
}
