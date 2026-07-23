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

class LoginMfaScreen extends StatefulWidget {
  final String mfaToken;

  const LoginMfaScreen({super.key, required this.mfaToken});

  @override
  State<LoginMfaScreen> createState() => _LoginMfaScreenState();
}

class _LoginMfaScreenState extends State<LoginMfaScreen> {
  bool isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool _validateCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter the authenticator code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (code.length < 6 || code.length > 16) {
      Fluttertoast.showToast(
        msg: 'Enter a valid 6-digit code or backup code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    return true;
  }

  Future<void> _verifyMfa() async {
    if (!_validateCode()) return;
    setState(() => isLoading = true);
    try {
      final response = await AuthService.verifyMfa(
        VerifyMfaPayload(
          mfaToken: widget.mfaToken,
          code: _codeController.text.trim(),
        ),
      );
      if (!response.success || response.token == null) {
        final msg = response.message.isNotEmpty
            ? response.message
            : 'Invalid code';
        Fluttertoast.showToast(
          msg: msg,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        if (msg.toLowerCase().contains('expired') ||
            msg.toLowerCase().contains('invalid or expired')) {
          if (mounted) context.goNamed(RouteNames.LOGIN_SCREEN);
        } else {
          _codeController.clear();
        }
        return;
      }

      trackAction(AnalyticsEvent.otpVerified, {
        'label': 'Verify MFA',
        'detail': 'verified',
        'is_profile_complete': response.isProfileComplete == true,
      });

      if (!mounted) return;
      if (response.isProfileComplete == true) {
        final user = await AuthService.verifySession();
        await LocalStorage.setString('userId', user.user?.id ?? '');
        if (user.user?.id != null) {
          await AnalyticsService.instance.identify(user.user!.id!, {
            if (user.user!.mobile != null) 'mobile': user.user!.mobile,
          });
        }
        if (!mounted) return;
        context.read<UserProvider>().setUser(user.user!);
        context.goNamed(RouteNames.HOME_SCREEN);
      } else {
        context.pushNamed(RouteNames.SETUP_SCREEN);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to verify code. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(HugeIconsSolid.arrowLeft02),
                    Text('Back'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF6400E0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  color: Color(0xFF6400E0),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Authenticator code',
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 22,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code from Google Authenticator, or use a backup code.',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 13,
                  height: 1.4,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                maxLength: 16,
                onSubmitted: (_) => _verifyMfa(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '6-digit or backup code',
                  filled: true,
                  fillColor: SharePerksColors.surfaceLight,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Color(0xFF6400E0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                    borderSide: BorderSide(
                      color: SharePerksColors.inputBorderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                    borderSide: BorderSide(
                      color: SharePerksColors.inputBorderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SharePerksRadii.md),
                    borderSide: const BorderSide(
                      color: Color(0xFF6400E0),
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 16,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyMfa,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
