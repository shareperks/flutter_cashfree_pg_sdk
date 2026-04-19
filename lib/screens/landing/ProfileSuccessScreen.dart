import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

class ProfileSuccessScreen extends StatefulWidget {
  const ProfileSuccessScreen({super.key});

  @override
  State<ProfileSuccessScreen> createState() => _ProfileSuccessScreenState();
}

class _ProfileSuccessScreenState extends State<ProfileSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _goNextAfterSuccess();
  }

  Future<void> _goNextAfterSuccess() async {
    await Future<void>.delayed(const Duration(seconds: 2)).then((value) {
      context.goNamed(RouteNames.INFO_SLIDE_SCREEN);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Lottie.asset(
              Assets.ASSETS_LOTTIE_SUCCESSFULCHECK_JSON,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
              repeat: false,
            ),
            Text(
              'Profile details saved',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
