import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/ResendOtp.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/network.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/auth_model.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool isLoading = false;
  TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  bool validateOtp() {
    if (otpController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter the OTP.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (otpController.text.length != 4) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid OTP.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  void resendOtp() async {
    try {
      final response = await AuthService.login(
        LoginMobilePayload(phone: widget.phone),
      );
      trackAction(AnalyticsEvent.otpResent, {'label': 'Resend OTP'});
      if (!response.success) {
        Fluttertoast.showToast(
          msg: 'OTP sent successfully.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return;
      }
      Fluttertoast.showToast(
        msg: 'OTP sent successfully.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to resend OTP. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void verifyOtp() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await AuthService.verifyOtp(
        VerifyOtpMobilePayload(phone: widget.phone, otp: otpController.text),
      );
      if (!response.success) {
        trackAction(AnalyticsEvent.otpFailed, {
          'label': 'Verify OTP',
          'detail': 'failed',
          'reason': 'invalid_response',
          if (response.message.isNotEmpty == true) 'message': response.message,
        });
        Fluttertoast.showToast(
          msg: response.message,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      await TokenManager.setToken(response.token!);
      trackAction(AnalyticsEvent.otpVerified, {
        'label': 'Verify OTP',
        'detail': 'verified',
        'is_profile_complete': response.isProfileComplete == true,
      });
      if (response.isProfileComplete == true) {
        final user = await AuthService.verifySession();
        await LocalStorage.setString("userId", user.user?.id ?? "");
        if (user.user?.id != null) {
          await AnalyticsService.instance.identify(user.user!.id!, {
            if (user.user!.mobile != null) 'mobile': user.user!.mobile,
          });
        }
        context.read<UserProvider>().setUser(user.user!);
        context.goNamed(RouteNames.HOME_SCREEN);
        return;
      } else {
        context.pushNamed(RouteNames.SETUP_SCREEN);
        return;
      }
    } catch (e) {
      trackAction(AnalyticsEvent.otpFailed, {
        'label': 'Verify OTP',
        'detail': 'failed',
        'reason': 'exception',
      });
      Fluttertoast.showToast(
        msg: 'Failed to verify OTP. Please try again.',
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
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [Icon(HugeIconsSolid.arrowLeft02), Text('Back')],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Enter OTP',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Enter the 4-digit OTP we sent to you via SMS',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 10),
            Pinput(
              length: 4,
              onCompleted: (value) {
                verifyOtp();
              },
              autofocus: true,
              controller: otpController,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 16,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: SharePerksColors.inputFillLight,
                  border: Border.all(color: SharePerksColors.inputBorderLight),
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                ),
              ),
            ),
            SizedBox(height: 5),
            ResendOtp(
              seconds: 120,
              onResend: () {
                resendOtp();
              },
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                if (!validateOtp()) {
                  return;
                }
                verifyOtp();
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
                  : Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
