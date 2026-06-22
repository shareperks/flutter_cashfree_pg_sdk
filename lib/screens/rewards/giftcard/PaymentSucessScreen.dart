import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    this.orderId,
    this.claimedId,
    this.amount,
  });

  final String? orderId;
  final String? claimedId;
  final double? amount;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _goNextAfterSuccess();
  }

  Future<void> _goNextAfterSuccess() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _navigateNext();
  }

  void _navigateNext() {
    final claimedId = widget.claimedId;
    if (claimedId != null && claimedId.isNotEmpty) {
      context.pushReplacementNamed(
        RouteNames.CLAIMED_GIFTCARD_SCREEN,
        extra: {'claimedId': claimedId},
      );
      return;
    }
    context.pushReplacementNamed(RouteNames.CLAIMED_PERKS_SCREEN);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.amount;

    return Scaffold(
      backgroundColor: SharePerksColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Lottie.asset(
                Assets.ASSETS_LOTTIE_SUCCESSFULCHECK_JSON,
                width: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.contain,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 22,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (amount != null && amount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Your gift card is being prepared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount paid: ₹${amount.round()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SharePerksColors.accent,
                    fontSize: 16,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _navigateNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: SharePerksColors.accent,
                  ),
                  child: const Text('View my perks'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
