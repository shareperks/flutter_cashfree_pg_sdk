import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shareperks/constants/keys.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/firebase_options.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/consent_manager.dart';
import 'package:shareperks/integrations/analytics/deep_link_tracker.dart';
import 'package:shareperks/integrations/analytics/install_attribution.dart';
import 'package:shareperks/integrations/onesignal_push.dart';
import 'package:shareperks/integrations/razorpay_payment.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'constants/theme_data.dart';

const _firstOpenKey = 'analytics_first_open_seen_v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('[firebase] initializeApp failed: $e\n$st');
  }

  RazorpayPayment.init();
  await OneSignalPush.init();

  // Consent Mode v2: apply stored (or implicit) consent before first events.
  if (await ConsentManager.read() == ConsentState.unknown) {
    await ConsentManager.grant();
  }

  await AnalyticsService.instance.init(
    trackingApiBaseUrl: Host.listingUrl,
    getAuthToken: () async => LocalStorage.getToken(),
  );
  await AnalyticsService.instance.onConsentChanged(
    await ConsentManager.isGranted(),
  );

  // Play Install Referrer (Google Ads deferred attribution on Android).
  unawaited(InstallAttribution.captureOnce());
  // Direct deep links + UTM capture.
  unawaited(DeepLinkTracker.instance.start());

  // is_first_open is true on the very first cold start of this install.
  final seenFirstOpen = LocalStorage.getString(_firstOpenKey) == '1';
  if (!seenFirstOpen) {
    await LocalStorage.setString(_firstOpenKey, '1');
  }
  unawaited(
    AnalyticsService.instance.track(AnalyticsEvent.appOpened, {
      'is_first_open': !seenFirstOpen,
    }),
  );

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
  DateTime? _pausedAt;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        isConnected = false;
        unawaited(
          AnalyticsService.instance.track(AnalyticsEvent.connectivityLost),
        );
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
    _connSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
        unawaited(
          AnalyticsService.instance.track(
            AnalyticsEvent.appBackgrounded,
            AnalyticsService.instance.backgroundProps(),
          ),
        );
        // Best-effort flush before the OS suspends us.
        unawaited(AnalyticsService.instance.flush());
        break;
      case AppLifecycleState.resumed:
        final pausedFor = _pausedAt != null
            ? DateTime.now().difference(_pausedAt!).inMilliseconds
            : null;
        _pausedAt = null;
        unawaited(
          AnalyticsService.instance.track(AnalyticsEvent.appForegrounded, {
            'paused_for_ms': ?pausedFor,
          }),
        );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
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
