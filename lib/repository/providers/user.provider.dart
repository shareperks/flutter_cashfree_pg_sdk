import 'package:flutter/material.dart';
import 'package:shareperks/repository/services/auth/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? user;

  void setUser(UserModel user) {
    this.user = user;
    notifyListeners();
  }

  void clearUser() {
    user = null;
    notifyListeners();
  }
}
