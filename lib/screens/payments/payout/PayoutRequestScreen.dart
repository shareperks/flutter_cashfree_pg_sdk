import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/payout_request_model.dart';
import 'package:shareperks/repository/services/wallet/wallet.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';

class PayoutRequestScreen extends StatefulWidget {
  final double amount;
  const PayoutRequestScreen({super.key, required this.amount});

  @override
  State<PayoutRequestScreen> createState() => _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends State<PayoutRequestScreen> {
  final TextEditingController upiId = TextEditingController();

  static final RegExp _upiPattern = RegExp(
    r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z][a-zA-Z0-9.-]{1,63}$',
  );

  @override
  void dispose() {
    upiId.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    final err = _validateForSubmit();
    if (err != null) {
      _showSnack(err);
      return;
    }
    final upi = upiId.text.trim();
    try {
      final resp = await WalletDataService.requestPayout(
        PayoutRequestPayload(amount: widget.amount, upi: upi),
      );
      if (resp.success == true) {
        context.pop();
        context.pop();
        context.pushReplacementNamed(RouteNames.PAYOUT_SUCCESS_SCREEN);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data['message'] ?? 'Could not submit payout';
      _showSnack(msg);
    } catch (_) {
      _showSnack('Could not submit payout');
    }
  }

  Future<void> _onProceedToPayout() => submitRequest();

  void _showSnack(String message) {
    Fluttertoast.showToast(msg: message);
  }

  bool _isValidUpi(String raw) {
    final v = raw.trim();
    return _upiPattern.hasMatch(v);
  }

  String? _validateForSubmit() {
    if (widget.amount <= 0) {
      return 'Invalid withdrawal amount';
    }
    final upi = upiId.text.trim();
    if (upi.isEmpty) {
      return 'Please enter your UPI ID';
    }
    if (!_isValidUpi(upi)) {
      return 'Enter a valid UPI ID (e.g. yourname@paytm)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Withdraw"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.info,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            BorderCard(
              width: MediaQuery.of(context).size.width,
              color: SharePerksColors.info,
              padding: EdgeInsets.all(15),
              borderWidth: 1,
              borderRadius: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: const Color(0x3F5182FE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For withdrawal of',
                      style: TextStyle(
                        color: const Color(0xFF5182FE) /* Information */,
                        fontSize: 16,
                        fontFamily: 'Albert Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹ ${widget.amount}',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 22,
                        fontFamily: 'Albert Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Text(
                    'Enter UPI id',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 12,
                      fontFamily: 'Albert Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextField(
                    controller: upiId,
                    decoration: InputDecoration(hint: Text("Enter UPI Id")),
                  ),
                ],
              ),
            ),
            Spacer(),
            Copyright(),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(SharePerksColors.info),
              ),
              onPressed: _onProceedToPayout,
              child: Text("Proceed To Payout"),
            ),
          ],
        ),
      ),
    );
  }
}
