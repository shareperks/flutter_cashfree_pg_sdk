import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/services/auth/mfa_service.dart';
import 'package:soui/elements/SpScafold.dart';

class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _qrCode;
  String? _secret;
  final TextEditingController _codeController = TextEditingController();

  static const Color _brand = Color(0xFF6400E0);

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startSetup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MfaService.setup();
      if (!mounted) return;
      if (!res.success) {
        final msg = res.message ?? 'Could not start 2FA setup.';
        if (msg.toLowerCase().contains('already enabled')) {
          Fluttertoast.showToast(
            msg: msg,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
          context.pop();
          return;
        }
        setState(() {
          _error = msg;
          _loading = false;
        });
        return;
      }
      setState(() {
        _qrCode = res.qrCode;
        _secret = res.secret;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not start 2FA setup. Try again.';
        _loading = false;
      });
    }
  }

  Uint8List? _qrBytes() {
    final raw = _qrCode;
    if (raw == null || raw.isEmpty) return null;
    try {
      final comma = raw.indexOf(',');
      final b64 = comma >= 0 ? raw.substring(comma + 1) : raw;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _copySecret() async {
    final secret = _secret;
    if (secret == null || secret.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: secret));
    Fluttertoast.showToast(
      msg: 'Secret copied',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  Future<void> _enable() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      Fluttertoast.showToast(
        msg: 'Enter the 6-digit code from your authenticator.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await MfaService.enable(code);
      if (!mounted) return;
      if (!res.success) {
        Fluttertoast.showToast(
          msg: res.message.isNotEmpty ? res.message : 'Invalid code',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        if (res.message.toLowerCase().contains('setup not started')) {
          await _startSetup();
        }
        _codeController.clear();
        setState(() => _submitting = false);
        return;
      }
      context.pushReplacementNamed(
        RouteNames.MFA_BACKUP_CODES_SCREEN,
        extra: {'backupCodes': res.backupCodes},
      );
    } catch (_) {
      Fluttertoast.showToast(
        msg: 'Could not enable 2FA. Try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _spacedSecret(String secret) {
    final buf = StringBuffer();
    for (var i = 0; i < secret.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(secret[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final qrBytes = _qrBytes();
    final pinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: TextStyle(
        color: SharePerksColors.textPrimaryLight,
        fontSize: 18,
        fontFamily: SharePerksFonts.inter,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
      ),
    );

    return SpScafold(
      appBar: AppBar(
        leading: const AppBackButton(),
        toolbarHeight: 40,
        title: const Text('Enable 2FA'),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SharePerksColors.textPrimaryLight,
                            fontSize: 16,
                            fontFamily: SharePerksFonts.albertSans,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _startSetup,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protect your account',
                              style: TextStyle(
                                color: SharePerksColors.textPrimaryLight,
                                fontSize: 22,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scan the QR in Google Authenticator or Authy, then enter the code below.',
                              style: TextStyle(
                                color: SharePerksColors.textSecondaryLight,
                                fontSize: 12,
                                height: 1.45,
                                fontFamily: SharePerksFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Container(
                                width: 228,
                                height: 228,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: SharePerksColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: qrBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          qrBytes,
                                          width: 188,
                                          height: 188,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Can’t scan?',
                              style: TextStyle(
                                color: SharePerksColors.textPrimaryLight,
                                fontSize: 14,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter this key in your authenticator app',
                              style: TextStyle(
                                color: SharePerksColors.textSecondaryLight,
                                fontSize: 12,
                                fontFamily: SharePerksFonts.inter,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: SharePerksColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(SharePerksRadii.md),
                              child: InkWell(
                                onTap: _copySecret,
                                borderRadius:
                                    BorderRadius.circular(SharePerksRadii.md),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _spacedSecret(_secret ?? ''),
                                          style: TextStyle(
                                            color: SharePerksColors
                                                .textPrimaryLight,
                                            fontSize: 14,
                                            fontFamily: SharePerksFonts.inter,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.1,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          color: _brand,
                                          fontSize: 13,
                                          fontFamily: SharePerksFonts.inter,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Verification code',
                              style: TextStyle(
                                color: SharePerksColors.textPrimaryLight,
                                fontSize: 14,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter the 6-digit code from your authenticator',
                              style: TextStyle(
                                color: SharePerksColors.textSecondaryLight,
                                fontSize: 12,
                                fontFamily: SharePerksFonts.inter,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Pinput(
                              length: 6,
                              controller: _codeController,
                              autofocus: false,
                              onCompleted: (_) => _enable(),
                              defaultPinTheme: pinTheme,
                              focusedPinTheme: pinTheme.copyWith(
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    SharePerksRadii.md,
                                  ),
                                ),
                              ),
                              submittedPinTheme: pinTheme.copyWith(
                                decoration: BoxDecoration(
                                  color: _brand.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    SharePerksRadii.md,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _enable,
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Confirm & enable'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
