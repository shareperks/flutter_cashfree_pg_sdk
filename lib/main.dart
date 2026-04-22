import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'constants/theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => HomeDataProvider()),
      ],
      child: SharePerksApp(),
    ),
  );
}

class SharePerksApp extends StatefulWidget {
  const SharePerksApp({super.key});

  @override
  State<SharePerksApp> createState() => _SharePerksAppState();
}

class _SharePerksAppState extends State<SharePerksApp>
    with WidgetsBindingObserver {
  bool isConnected = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        isConnected = false;
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: "Please check your internet connection",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        if (!isConnected) {
          Fluttertoast.cancel();
          Fluttertoast.showToast(
            msg: "You are back online",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
        isConnected = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //cancel the connectivity listener
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SharePerksColors.backgroundLight,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: MaterialApp.router(
          title: 'SharePerks',
          theme: SharePerksTheme.light,
          darkTheme: SharePerksTheme.light,
          themeMode: ThemeMode.system,
          showSemanticsDebugger: false,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: ScaffoldMessengerKey,
          routerConfig: router,
        ),
      ),
    );
  }
}
