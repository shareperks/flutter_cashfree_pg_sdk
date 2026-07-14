import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/analytics_service.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/auth_model.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  bool isReferralCodeVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(AnalyticsEvent.profileSetupStarted);
  }

  bool validateForm() {
    if (firstNameController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your first name.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (lastNameController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your last name.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (emailController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your email.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (emailController.text.isNotEmpty &&
        !emailController.text.contains('@')) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid email.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  String? _referralCodeIfProvided() {
    final code = referralCodeController.text.trim();
    return code.isEmpty ? null : code;
  }

  void completeProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await AuthService.completeProfile(
        CompleteProfilePayload(
          name: "${firstNameController.text} ${lastNameController.text}",
          email: emailController.text,
          referralCode: _referralCodeIfProvided(),
        ),
      );
      if (!response.success) {
        Fluttertoast.showToast(
          msg: response.message,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      await LocalStorage.setString("userId", response.user?.id ?? "");
      if (response.user?.id != null) {
        await AnalyticsService.instance.identify(response.user!.id!, {
          if (response.user!.mobile != null) 'mobile': response.user!.mobile,
        });
      }
      trackAction(AnalyticsEvent.profileCompleted, {'label': 'Complete Profile'});
      trackAction(AnalyticsEvent.signupCompleted, {
        'label': 'Complete Signup',
        'has_referral': _referralCodeIfProvided() != null,
      });
      context.read<UserProvider>().setUser(response.user!);
      context.goNamed(RouteNames.PROFILE_SUCCESS_SCREEN);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to complete profile. Please try again.',
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
              'Setup your profile',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 22,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Please fill the following details carefully',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      hintText: 'First Name',
                      hintStyle: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Last Name',
                      hintStyle: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 1),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                Text(
                  'Got a referral code?',
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      isReferralCodeVisible = !isReferralCodeVisible;
                      if (!isReferralCodeVisible) {
                        referralCodeController.clear();
                      }
                    });
                  },
                  child: Text(
                    isReferralCodeVisible ? 'Remove it' : 'Add it in',
                    style: TextStyle(
                      color: SharePerksColors.accent,
                      fontSize: 14,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: SharePerksColors.accent,
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Builder(
              builder: (context) {
                return isReferralCodeVisible
                    ? TextField(
                        controller: referralCodeController,
                        decoration: InputDecoration(
                          hintText: 'Referral Code (optional)',
                          hintStyle: TextStyle(
                            color: SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SharePerksColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SharePerksRadii.md),
                ),
              ),
              onPressed: () {
                if (!validateForm()) {
                  return;
                }
                completeProfile();
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
                  : Text('Finish setup'),
            ),
          ],
        ),
      ),
    );
  }
}
