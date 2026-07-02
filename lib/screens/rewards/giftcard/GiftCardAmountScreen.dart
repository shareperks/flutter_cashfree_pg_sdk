import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/api_error_model.dart';
import 'package:shareperks/repository/models/gift_card_proceed_model.dart';
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/integrations/cashfree_payment.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/repository/services/payment/cashfree.service.dart';
import 'package:shareperks/repository/services/payment/giftcard_payment.service.dart';
import 'package:shareperks/screens/rewards/utils/rewardCalc.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/amount_picker.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';

class GiftCardAmountScreen extends StatefulWidget {
  final String rewardId;
  final bool isEligible;
  const GiftCardAmountScreen({
    super.key,
    required this.rewardId,
    required this.isEligible,
  });
  @override
  State<GiftCardAmountScreen> createState() => _GiftCardAmountScreenState();
}

class _GiftCardAmountScreenState extends State<GiftCardAmountScreen> {
  bool _loading = true;
  bool _paying = false;
  GiftcardDetailResponse? data;
  String? _errorMessage;
  int? amount;
  final TextEditingController _amountController = TextEditingController();

  GiftcardAmount? get _amountConfig => data?.data?.amount;

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getGiftcardDetail(widget.rewardId);
      final initial = _amountConfig?.min?.round();
      amount = initial != null && initial > 0 ? initial : null;
      if (_amountConfig?.isAmountEditable == true && amount != null) {
        _amountController.text = '$amount';
      } else {
        _amountController.clear();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onEditableAmountChanged(String raw) {
    final parsed = int.tryParse(raw.trim());
    final min = _amountConfig?.min?.round();
    final max = _amountConfig?.max?.round();

    int? next;
    if (parsed != null && parsed > 0) {
      final withinMin = min == null || parsed >= min;
      final withinMax = max == null || parsed <= max;
      if (withinMin && withinMax) {
        next = parsed;
      }
    }

    setState(() => amount = next);
  }

  String? _editableAmountErrorText() {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount';
    }
    final min = _amountConfig?.min?.round();
    final max = _amountConfig?.max?.round();
    if (min != null && parsed < min) {
      return 'Minimum amount is ₹$min';
    }
    if (max != null && parsed > max) {
      return 'Maximum amount is ₹$max';
    }
    return null;
  }

  String _editableAmountHint() {
    final min = _amountConfig?.min?.round();
    final max = _amountConfig?.max?.round();
    if (min != null && max != null) {
      return 'Enter amount between ₹$min and ₹$max';
    }
    if (min != null) return 'Minimum ₹$min';
    if (max != null) return 'Maximum ₹$max';
    return 'Enter amount';
  }

  Widget _buildEditableAmountField() {
    final errorText = _editableAmountErrorText();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: _editableAmountHint(),
            errorText: errorText,
          ),
          onChanged: _onEditableAmountChanged,
        ),
      ],
    );
  }

  Widget _buildAmountSelector() {
    if (_amountConfig?.isAmountEditable == true) {
      return _buildEditableAmountField();
    }

    final options = _amountConfig?.options ?? [];
    if (options.isNotEmpty || _amountConfig?.isAmountSelectable == true) {
      return AmountPicker(
        selectedAmount: amount,
        onAmountDeselected: () {
          setState(() => amount = null);
        },
        onAmountSelected: (value) {
          setState(() => amount = value);
        },
        amounts: options.map((v) => v.round()).toList(),
      );
    }

    final fixed = _amountConfig?.min?.round();
    if (fixed != null && fixed > 0) {
      return Text(
        '₹ $fixed',
        style: TextStyle(
          color: SharePerksColors.primary,
          fontSize: 22,
          fontFamily: SharePerksFonts.albertSans,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  GiftCardCalc? get _calc {
    final detail = data?.data;
    if (detail == null) return null;
    return GiftCardCalc(detail, isEligible: widget.isEligible);
  }

  GiftCardCalcCalcData? get _pricing {
    final selected = amount;
    if (selected == null || selected <= 0) return null;
    return _calc?.calc(selected.toDouble());
  }

  Future<void> _onProceedToPay() async {
    final pricing = _pricing;
    if (pricing == null || _paying) return;

    setState(() => _paying = true);
    try {
      final order = await GiftCardPaymentService.proceedGiftCardPayment(
        GiftCardProceedRequest(
          payAmount: pricing.discountedAmount,
          rewardAmount: pricing.amount,
          creditId: widget.rewardId,
          eligible: widget.isEligible,
        ),
      );

      await CashfreePayment.startWebCheckout(
        orderId: order.orderId,
        paymentSessionId: order.sessionId,
        environment: CFEnvironment.PRODUCTION,
        onSuccess: (orderId) async {
          if (!mounted) return;
          String? claimedId;
          try {
            final resp = await CashfreePaymentService.fetchOrderStatus(orderId);
            if (resp['success'] == true) {
              final data = resp['data'];
              if (data is Map<String, dynamic>) {
                claimedId = data['claimedId']?.toString();
              }
              claimedId ??= resp['claimedId']?.toString();
            }
          } catch (_) {}
          if (!mounted) return;
          context.pushReplacementNamed(
            RouteNames.GIFTCARD_PAYMENT_SUCCESS_SCREEN,
            extra: {
              'orderId': orderId,
              if (claimedId != null) 'claimedId': claimedId,
              'amount': pricing.discountedAmount,
            },
          );
        },
        onError: (error, _) {
          if (!mounted) return;
          Fluttertoast.showToast(msg: error.getMessage() ?? 'Payment failed');
        },
      );
    } on ApiErrorResponse catch (e) {
      print(e);
      if (mounted) {
        Fluttertoast.showToast(msg: e.displayMessage);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        Fluttertoast.showToast(msg: 'Could not start payment');
      }
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricing = _pricing;

    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.accent,
        leading: AppBackButton(),
        title: Text("Claim perk"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
      ),
      body: _loading
          ? const GiftCardRewardShimmer()
          : _errorMessage != null
          ? Center(
              child: Text('Failed to load perk.', textAlign: TextAlign.center),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await loadData();
              },
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    if (widget.isEligible)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                        ).copyWith(top: 18),
                        child: Image.asset(
                          Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          PerkBasicInfo(
                            onTickerTap: () {
                              context.pushNamed(
                                RouteNames.COMPANY_SCREEN,
                                extra: {"companyId": data?.data?.company?.id},
                              );
                            },
                            data: PerkBasicInfoData(
                              imageUrl:
                                  data?.data?.basicInfo?.bannerImage ?? '',
                              typeLabel: data?.data?.basicInfo?.type ?? '',
                              title: data?.data?.basicInfo?.title ?? '',
                              tickerValue: data?.data?.basicInfo?.ticker ?? '',
                              perkIdValue: data?.data?.basicInfo?.perkId ?? '',
                              detailsBody: null,
                            ),
                          ),
                          BorderCard(
                            padding: EdgeInsets.all(18),
                            isGradientBackground: false,
                            color: SharePerksColors.accent,
                            borderWidth: 1,
                            borderRadius: 18,
                            child: CollapseCard(
                              color: SharePerksColors.primary,
                              title: Text(
                                'Choose Amount',
                                style: TextStyle(
                                  color: SharePerksColors.primary,
                                  fontSize: 16,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: _buildAmountSelector(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What you pay',
                            style: TextStyle(
                              color: SharePerksColors.accent,
                              fontSize: 16,
                              fontFamily: SharePerksFonts.albertSans,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFF6400E0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: Color(0x266400E0),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 10,
                                  children: [
                                    Text(
                                      pricing?.formattedPayable ?? '₹ —',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: SharePerksColors.primary,
                                        fontSize: 22,
                                        fontFamily: SharePerksFonts.albertSans,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (pricing != null && pricing.hasDiscount)
                                      Text(
                                        pricing.formattedFaceValue,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: SharePerksColors
                                              .textSecondaryLight,
                                          fontSize: 13,
                                          fontFamily: SharePerksFonts.inter,
                                          fontWeight: FontWeight.w400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  pricing?.formattedPercentOff ?? '—',
                                  style: TextStyle(
                                    color: SharePerksColors.accent,
                                    fontSize: 22,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          PerkTerms(
                            onViewAll: () {
                              context.pushNamed(
                                RouteNames.REWARD_TERM_VIEW_SCREEN,
                                extra: {"contentId": data?.data?.content?.id},
                              );
                            },
                            termsAndConditions:
                                data?.data?.content?.termsAndConditions ?? '',
                          ),
                          Copyright(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Builder(
        builder: (context) {
          if (_loading) {
            return SizedBox(height: 0);
          }
          return Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  SharePerksColors.accent,
                ),
              ),
              onPressed: _pricing == null || _paying ? null : _onProceedToPay,
              child: _paying
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Proceed to Claim Credit'),
            ),
          );
        },
      ),
    );
  }
}
