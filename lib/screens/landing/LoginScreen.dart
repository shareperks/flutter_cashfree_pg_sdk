import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/services/auth/auth_model.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  bool validateMobile() {
    if (mobileController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your mobile number.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (mobileController.text.length != 10) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid mobile number.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  void login() async {
    trackAction(AnalyticsEvent.loginStarted, {});
    setState(() {
      isLoading = true;
    });
    try {
      final response = await AuthService.login(
        LoginMobilePayload(phone: mobileController.text),
      );
      if (!response.success) {
        Fluttertoast.showToast(
          msg: response.message,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      context.pushNamed(
        RouteNames.OTP_SCREEN,
        extra: {'phone': mobileController.text},
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to login. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 5,
          children: [
            SizedBox(height: 60),
            Text(
              'Welcome back',
              style: TextStyle(
                color: SharePerksColors.accent,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Login to your account',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Login to your Shareperks account using your mobile number',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.phone,
              controller: mobileController,
              autofillHints: [AutofillHints.telephoneNumber],
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // unfocus the keyboard
                FocusScope.of(context).unfocus();
                if (!validateMobile()) {
                  return;
                }
                login();
              },
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Get OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
