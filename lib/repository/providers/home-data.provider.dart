import 'package:flutter/material.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';

class HomeDataProvider extends ChangeNotifier {
  HomeDataModel? homeData;
  void setHomeData(HomeDataModel homeData) {
    this.homeData = homeData;
    notifyListeners();
  }
}
