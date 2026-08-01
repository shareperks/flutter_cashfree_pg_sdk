import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/WalletCard.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:soui/elements/SpScafold.dart';

class PayoutScreen extends StatefulWidget {
  final double amount;
  const PayoutScreen({super.key, required this.amount});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    Fluttertoast.showToast(msg: message);
  }

  void _onWithdrawPressed() {
    final raw = amountController.text.trim();
    if (raw.isEmpty) {
      _showSnack('Please enter an amount');
      return;
    }
    final value = double.tryParse(raw);
    if (value == null) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (value <= 0) {
      _showSnack('Amount must be greater than zero');
      return;
    }
    if (value > widget.amount) {
      _showSnack(
        'Amount cannot exceed available balance (₹${widget.amount.toStringAsFixed(2)})',
      );
      return;
    }

    trackAction(AnalyticsEvent.payoutStarted, {
      'amount': value,
    });

    context.pushNamed(
      RouteNames.PAYOUT_REQUEST_SCREEN,
      extra: <String, dynamic>{'amount': value.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Withdraw"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.primary,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width,
          child: Column(
            spacing: 10,
            children: [
              SizedBox(height: 20),
              Image.asset(Assets.ASSETS_ICONS_PAYOUT_PNG, width: 200),
              Text(
                'Withdraw',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 22,
                  fontFamily: 'Albert Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Withdraw money from your wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 10),
              WalletCard(amount: widget.amount),
              SizedBox(height: 5),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hint: const Text('Enter Amount'),
                  helper: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: amountController,
                    builder: (context, value, _) {
                      final entered = double.tryParse(value.text.trim()) ?? 0.0;
                      final remaining = widget.amount - entered;
                      return Row(
                        spacing: 5,
                        children: [
                          Text(
                            'Remaining Balance:',
                            style: TextStyle(
                              color: SharePerksColors.textSecondaryLight,
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '₹ ${remaining.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: remaining < 0
                                  ? SharePerksColors.error
                                  : SharePerksColors.textPrimaryLight,
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    SharePerksColors.primary,
                  ),
                ),
                onPressed: _onWithdrawPressed,
                child: Text("Withdraw Money"),
              ),
              Copyright(),
            ],
          ),
        ),
      ),
    );
  }
}
