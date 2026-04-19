import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<bool> checkInternetConnection() async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.any((element) => element == ConnectivityResult.wifi)) {
    return true;
  }
  if (connectivityResult.contains(ConnectivityResult.ethernet) ||
      connectivityResult.any(
        (element) => element == ConnectivityResult.bluetooth,
      )) {
    return true;
  }
  if (connectivityResult.contains(ConnectivityResult.vpn) ||
      connectivityResult.any((element) => element == ConnectivityResult.vpn)) {
    return true;
  }
  if (connectivityResult.contains(ConnectivityResult.other) ||
      connectivityResult.any(
        (element) => element == ConnectivityResult.other,
      )) {
    return true;
  }
  return false;
}

Future getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return {
      'model': androidInfo.model,
      'version': androidInfo.version.release,
      'manufacturer': androidInfo.manufacturer,
      'platform': 'android',
      'deviceId': androidInfo.id,
      'data': androidInfo.data,
    };
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return {
      'model': iosInfo.model,
      'version': iosInfo.systemVersion,
      'platform': 'ios',
      'deviceId': iosInfo.identifierForVendor,
      'data': iosInfo.data,
    };
  }
}

Future getPackageInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return {
    'packageName': packageInfo.packageName,
    'version': packageInfo.version,
    'buildNumber': packageInfo.buildNumber,
    'installerStore': packageInfo.installerStore,
    'appName': packageInfo.appName,
    'installTime': packageInfo.installTime,
    "data": packageInfo.data,
  };
}
