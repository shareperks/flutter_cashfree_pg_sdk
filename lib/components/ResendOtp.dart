import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class ResendOtp extends StatefulWidget {
  final int seconds;
  final VoidCallback onResend;
  const ResendOtp({super.key, required this.seconds, required this.onResend});
  @override
  State<ResendOtp> createState() => _ResendOtpState();
}

class _ResendOtpState extends State<ResendOtp> {
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.seconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_secondsRemaining == 0) {
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _onResend() {
    if (_secondsRemaining > 0) return;
    widget.onResend();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        TextButton(
          onPressed: canResend ? _onResend : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Resend OTP',
            style: TextStyle(
              color: canResend
                  ? SharePerksColors.textSecondaryLight
                  : SharePerksColors.textSecondaryLight.withValues(alpha: 0.5),
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: canResend
                  ? SharePerksColors.textSecondaryLight
                  : SharePerksColors.textSecondaryLight.withValues(alpha: 0.5),
              decorationThickness: 1,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (!canResend)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                'in',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                  color: SharePerksColors.borderDark,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
