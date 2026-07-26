import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/EligibleRewardCard.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/journey_context.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/integrations/razorpay_payment.dart';
import 'package:shareperks/repository/models/api_error_model.dart';
import 'package:shareperks/repository/models/gift_card_proceed_model.dart';
import 'package:shareperks/repository/models/giftcard_coupon_model.dart';
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/repository/models/razorpay_verify_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/repository/services/payment/giftcard_payment.service.dart';
import 'package:shareperks/repository/services/payment/razorpay.service.dart';
import 'package:shareperks/screens/rewards/utils/rewardCalc.dart';
import 'package:shareperks/screens/rewards/utils/reward_eligibility.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/amount_picker.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';

class GiftCardAmountScreen extends StatefulWidget {
  final String rewardId;

  /// Route hint until detail loads. After load, API eligibility wins unless
  /// [forceNonHolder] is true.
  final bool isEligible;
  final bool isBrokerageEligible;

  /// User explicitly chose the standard / non-shareholder rate.
  final bool forceNonHolder;

  const GiftCardAmountScreen({
    super.key,
    required this.rewardId,
    required this.isEligible,
    this.isBrokerageEligible = false,
    this.forceNonHolder = false,
  });
  @override
  State<GiftCardAmountScreen> createState() => _GiftCardAmountScreenState();
}

class _GiftCardAmountScreenState extends State<GiftCardAmountScreen> {
  bool _loading = true;
  bool _paying = false;
  bool _paymentStarted = false;
  bool _paymentFinished = false;
  int _paymentCheckGeneration = 0;
  GiftcardDetailResponse? data;
  String? _errorMessage;
  int? amount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _applyingCoupon = false;
  GiftCardCouponApplyData? _appliedCoupon;
  GiftCardProceedPricing? _serverPricing;
  GiftcardAmount? get _amountConfig => data?.data?.amount;

  GiftcardEligibility? get _eligibility => data?.data?.eligibility;

  /// High → mid → low from detail API (route hints only before load / force).
  bool get _isEligible {
    if (widget.forceNonHolder) return false;
    return _eligibility?.isEligible ??
        data?.data?.basicInfo?.isEligible ??
        widget.isEligible;
  }

  bool get _isBrokerageEligible {
    if (widget.forceNonHolder) return false;
    return _eligibility?.isBrokerageEligible ??
        data?.data?.basicInfo?.isBrokerageEligible ??
        widget.isBrokerageEligible;
  }

  bool get _reqReimport => _eligibility?.isBrokerConnected?.reqReimport == true;

  RewardEligibilityTier get _tier => resolveRewardTier(
    isEligible: _isEligible,
    isBrokerageEligible: _isBrokerageEligible,
    reqReimport: _reqReimport,
  );

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getGiftcardDetail(widget.rewardId);
      JourneyContext.setNames(
        rewardName: data?.data?.basicInfo?.title,
        brandName: data?.data?.company?.name,
      );
      final initial = _amountConfig?.min?.round();
      amount = initial != null && initial > 0 ? initial : null;
      _clearCoupon(keepText: false);
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
    trackAction(AnalyticsEvent.giftcardAmountScreenViewed, {
      'reward_id': widget.rewardId,
      'is_eligible': widget.isEligible,
      'is_brokerage_eligible': widget.isBrokerageEligible,
      'force_non_holder': widget.forceNonHolder,
    });
    loadData();
  }

  void _onProceedButtonTap() {
    trackButtonClick('Proceed to Claim Credit', {
      'gift_card_name': data?.data?.basicInfo?.title ?? '',
      'is_eligible': _isEligible,
      'is_brokerage_eligible': _isBrokerageEligible,
      'eligibility_tier': _tier.name,
      'selected_amount': ?amount,
    });
    _onProceedToPay();
  }

  @override
  void dispose() {
    if (_paymentStarted && !_paymentFinished) {
      trackAction(AnalyticsEvent.giftcardPaymentAbandoned, {
        'abandon_stage': 'amount_screen',
        'gift_card_name': data?.data?.basicInfo?.title ?? '',
        'is_eligible': _isEligible,
        'is_brokerage_eligible': _isBrokerageEligible,
        'eligibility_tier': _tier.name,
        'selected_amount': ?amount,
      });
    }
    _paymentCheckGeneration++;
    _amountController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _clearCoupon({bool keepText = true}) {
    _appliedCoupon = null;
    _serverPricing = null;
    if (!keepText) _couponController.clear();
  }

  void _setAmount(int? next, {required String denominationType}) {
    setState(() {
      amount = next;
      _clearCoupon();
    });
    if (next != null) {
      trackAction(AnalyticsEvent.giftcardAmountSelected, {
        'label': 'Selected Amount',
        'amount': next,
        'denomination_type': denominationType,
      });
    }
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

    _setAmount(next, denominationType: 'editable');
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
          _setAmount(null, denominationType: 'fixed');
        },
        onAmountSelected: (value) {
          _setAmount(value, denominationType: 'fixed');
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
    return GiftCardCalc(
      detail,
      isEligible: _isEligible,
      isBrokerageEligible: _isBrokerageEligible,
    );
  }

  GiftCardCalcCalcData? get _pricing {
    final selected = amount;
    if (selected == null || selected <= 0) return null;
    return _calc?.calc(selected.toDouble());
  }

  /// SharePerks holding discount on the face amount (before coupon).
  double? get _sharePerksDiscountAmount {
    if (_serverPricing != null) {
      return _serverPricing!.sharePerksDiscount;
    }
    final pricing = _pricing;
    if (pricing == null || !pricing.hasDiscount) return null;
    return pricing.savings;
  }

  /// SharePerks-discounted payable — the base coupon apply uses.
  double? get _sharePerksPayable => _pricing?.discountedAmount;

  /// Final charge preview: SharePerks payable, then coupon if applied.
  /// After proceed with coupon, prefer server [pricing.chargeAmount].
  double? get _finalPayAmount {
    if (_serverPricing != null && _serverPricing!.chargeAmount > 0) {
      return _serverPricing!.chargeAmount;
    }
    final coupon = _appliedCoupon;
    if (coupon != null && coupon.payableAfterDiscount > 0) {
      return coupon.payableAfterDiscount;
    }
    return _sharePerksPayable;
  }

  String get _formattedFinalPayable {
    final pay = _finalPayAmount;
    if (pay == null) return '₹ —';
    return _formatInr(pay);
  }

  String _formatInr(double value) {
    final whole = value % 1 == 0;
    return '₹ ${value.toStringAsFixed(whole ? 0 : 2)}';
  }

  Future<void> _applyCoupon() async {
    final sharePerksPayable = _sharePerksPayable;
    if (sharePerksPayable == null || _applyingCoupon || _paying) return;

    final code = _couponController.text.trim();
    if (code.isEmpty) {
      _showCouponError('Enter a coupon code');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _applyingCoupon = true;
    });

    try {
      // Coupon is applied on the SharePerks-discounted amount (not face).
      // face → SharePerks → coupon.
      final applied = await RewardListingDataService.applyGiftcardCoupon(
        GiftCardCouponApplyRequest(code: code, orderAmount: sharePerksPayable),
      );
      if (!mounted) return;
      setState(() {
        _appliedCoupon = applied;
        _serverPricing = null;
        _couponController.text = applied.code;
      });
      Fluttertoast.showToast(
        msg: 'Coupon applied — saved ${applied.formattedDiscountApplied}',
        backgroundColor: SharePerksColors.success,
        textColor: Colors.white,
      );
    } on ApiErrorResponse catch (e) {
      _showCouponError(e.displayMessage);
    } catch (e) {
      _showCouponError(_friendlyCouponError(e));
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  /// Coupon errors surface as a red toast (inline field text can be clipped).
  void _showCouponError(String message) {
    if (!mounted) return;
    if (_appliedCoupon != null || _serverPricing != null) {
      setState(() {
        _appliedCoupon = null;
        _serverPricing = null;
      });
    }
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: SharePerksColors.error,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  String _friendlyCouponError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return 'Could not apply coupon';
    return raw;
  }

  void _removeCoupon() {
    setState(() => _clearCoupon(keepText: false));
  }

  /// "What the user is purchasing" — attached to every payment gateway event so
  /// the CRM/audit trail shows the gift card, its price, and the discount.
  Map<String, Object?> _purchaseProps(GiftCardCalcCalcData pricing) => {
    'payment_gateway': 'razorpay',
    'gift_card_name': data?.data?.basicInfo?.title ?? '',
    'brand_name': data?.data?.company?.name ?? '',
    'reward_id': widget.rewardId,
    'perk_type': 'giftcard',
    'face_value': pricing.amount,
    'amount': _finalPayAmount ?? pricing.discountedAmount,
    'shareperks_payable': pricing.discountedAmount,
    'shareperks_discount': _sharePerksDiscountAmount,
    'discount_percent': pricing.percent,
    'savings': pricing.savings,
    'is_eligible': _isEligible,
    'is_brokerage_eligible': _isBrokerageEligible,
    'eligibility_tier': _tier.name,
    if (_appliedCoupon != null) 'coupon_code': _appliedCoupon!.code,
    if (_appliedCoupon != null)
      'coupon_discount': _appliedCoupon!.discountApplied,
  };

  Future<void> _onProceedToPay() async {
    final pricing = _pricing;
    if (pricing == null || _paying) return;

    setState(() => _paying = true);
    final paymentCheckGeneration = ++_paymentCheckGeneration;
    _paymentStarted = true;
    try {
      trackAction(AnalyticsEvent.giftcardPaymentInitiated, {
        'label': 'Proceed to Payment',
        ..._purchaseProps(pricing),
      });

      // Always send SharePerks-discounted payable as payAmount.
      // - No coupon: server charges it as-is (legacy).
      // - With coupon: server applies coupon on this base (face → SP → coupon).
      final order = await GiftCardPaymentService.proceedGiftCardPayment(
        GiftCardProceedRequest(
          payAmount: pricing.discountedAmount,
          rewardAmount: pricing.amount,
          creditId: widget.rewardId,
          eligible: _isEligible,
          isBrokerageEligible: _isBrokerageEligible,
          journeyId: JourneyContext.currentJourneyId,
          couponCode: _appliedCoupon?.code,
        ),
      );

      if (mounted && order.pricing != null) {
        setState(() => _serverPricing = order.pricing);
      }

      trackAction(AnalyticsEvent.giftcardPaymentOrderCreated, {
        'label': 'Payment Order Created',
        ..._purchaseProps(pricing),
        'razorpay_order_id': order.razorpayOrderId,
        'order_id': order.orderId,
        if (order.pricing != null)
          'server_charge_amount': order.pricing!.chargeAmount,
        if (order.pricing != null)
          'server_coupon_discount': order.pricing!.couponDiscount,
        if (order.pricing != null)
          'server_shareperks_discount': order.pricing!.sharePerksDiscount,
      });

      trackAction(AnalyticsEvent.giftcardCheckoutOpened, {
        'label': 'Opened Payment Gateway',
        ..._purchaseProps(pricing),
        'razorpay_order_id': order.razorpayOrderId,
        'order_id': order.orderId,
      });

      RazorpayPayment.openCheckout(
        razorpayOrderId: order.razorpayOrderId,
        amountPaise: order.amountPaise,
        keyId: order.keyId,
        description: data?.data?.basicInfo?.title,
        onSuccess: (response) => _handleRazorpaySuccess(
          response: response,
          internalOrderId: order.orderId,
          paymentCheckGeneration: paymentCheckGeneration,
          amount: order.pricing?.chargeAmount ?? (order.amountPaise / 100),
        ),
        onError: (error) => _handleRazorpayError(
          error: error,
          paymentCheckGeneration: paymentCheckGeneration,
          razorpayOrderId: order.razorpayOrderId,
          internalOrderId: order.orderId,
        ),
      );
    } on ApiErrorResponse catch (e) {
      trackAction(AnalyticsEvent.giftcardPaymentFailed, {
        'label': 'Payment Failed',
        'detail': 'failed',
        ..._purchaseProps(pricing),
        'failure_stage': 'order_creation',
        'reason': e.displayMessage,
      });
      print(e);
      if (mounted) {
        Fluttertoast.showToast(msg: e.displayMessage);
        setState(() => _paying = false);
      }
    } catch (e) {
      trackAction(AnalyticsEvent.giftcardPaymentFailed, {
        'label': 'Payment Failed',
        'detail': 'failed',
        ..._purchaseProps(pricing),
        'failure_stage': 'checkout_launch',
        'reason': e.toString(),
      });
      print(e);
      if (mounted) {
        Fluttertoast.showToast(msg: 'Could not start payment');
        setState(() => _paying = false);
      }
    }
  }

  bool _isCurrentPaymentCheck(int generation) =>
      mounted && generation == _paymentCheckGeneration;

  Future<void> _handleRazorpaySuccess({
    required PaymentSuccessResponse response,
    required String internalOrderId,
    required int paymentCheckGeneration,
    required double amount,
  }) async {
    if (!_isCurrentPaymentCheck(paymentCheckGeneration)) return;

    final pricing = _pricing;
    final razorpayOrderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    try {
      RazorpayVerifyResponse? verified;
      try {
        verified = await RazorpayPaymentService.verifyPayment(
          RazorpayVerifyRequest(
            orderId: internalOrderId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          ),
        );
      } catch (_) {
        // Transient verify failure — one status fetch recovery.
        final status = await RazorpayPaymentService.fetchGiftCardOrderStatus(
          internalOrderId,
        );
        if (GiftCardOrderStatusData.isPaid(status)) {
          verified = RazorpayVerifyResponse(
            paid: true,
            claimedId: GiftCardOrderStatusData.claimedIdOf(status),
            orderStatus: GiftCardOrderStatusData.orderStatusOf(status),
            raw: status,
          );
        }
      }

      if (!_isCurrentPaymentCheck(paymentCheckGeneration)) return;

      if (verified == null || !verified.paid) {
        trackAction(AnalyticsEvent.giftcardPaymentFailed, {
          'label': 'Payment Failed',
          'detail': 'failed',
          if (pricing != null) ..._purchaseProps(pricing),
          'reason': 'payment_not_complete',
          'razorpay_order_id': razorpayOrderId,
          'order_id': internalOrderId,
          if (paymentId.isNotEmpty) 'razorpay_payment_id': paymentId,
          if (verified?.orderStatus != null)
            'order_status': verified!.orderStatus!,
        });
        Fluttertoast.showToast(msg: 'Payment is not complete');
        return;
      }

      _paymentFinished = true;

      trackAction(AnalyticsEvent.giftcardPaymentSucceeded, {
        'label': 'Payment Completed',
        'detail': 'success',
        if (pricing != null) ..._purchaseProps(pricing),
        'razorpay_order_id': razorpayOrderId,
        'order_id': internalOrderId,
        if (paymentId.isNotEmpty) 'razorpay_payment_id': paymentId,
        if (verified.orderStatus != null) 'order_status': verified.orderStatus!,
        if (verified.claimedId != null) 'claimed_id': verified.claimedId!,
      });

      if (!_isCurrentPaymentCheck(paymentCheckGeneration)) return;
      if (!mounted) return;

      context.pushReplacementNamed(
        RouteNames.GIFTCARD_PAYMENT_SUCCESS_SCREEN,
        extra: {
          'orderId': internalOrderId,
          if (verified.claimedId != null) 'claimedId': verified.claimedId,
          'amount': amount,
        },
      );
    } catch (_) {
      if (_isCurrentPaymentCheck(paymentCheckGeneration)) {
        Fluttertoast.showToast(msg: 'Payment is not complete');
      }
    } finally {
      if (_isCurrentPaymentCheck(paymentCheckGeneration)) {
        setState(() => _paying = false);
      }
    }
  }

  void _handleRazorpayError({
    required PaymentFailureResponse error,
    required int paymentCheckGeneration,
    required String razorpayOrderId,
    required String internalOrderId,
  }) {
    if (paymentCheckGeneration == _paymentCheckGeneration) {
      _paymentCheckGeneration++;
    }
    final pricing = _pricing;
    final cancelled = RazorpayPayment.isCheckoutCancelled(error);
    if (cancelled) {
      trackAction(AnalyticsEvent.giftcardPaymentCancelled, {
        'label': 'Payment Cancelled',
        'detail': 'cancelled',
        if (pricing != null) ..._purchaseProps(pricing),
        'reason': 'user_cancelled_checkout',
        'razorpay_order_id': razorpayOrderId,
        'order_id': internalOrderId,
      });
    } else {
      trackAction(AnalyticsEvent.giftcardPaymentFailed, {
        'label': 'Payment Failed',
        'detail': 'failed',
        if (pricing != null) ..._purchaseProps(pricing),
        'failure_stage': 'checkout',
        'reason': error.message ?? 'razorpay_checkout_error',
        'error_code': '${error.code}',
        'razorpay_order_id': razorpayOrderId,
        'order_id': internalOrderId,
      });
    }
    if (!mounted) return;
    // Quiet dismiss when the user closes Checkout; toast only on real failures.
    if (!cancelled) {
      Fluttertoast.showToast(msg: 'Payment Failed Please try again');
    }
    setState(() => _paying = false);
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
                    RewardEligibilityBanner(
                      isEligible: _isEligible,
                      isBrokerageEligible: _isBrokerageEligible,
                      listedOnExchange:
                          data?.data?.company?.listedOnExchange ?? true,
                      reqReimport: _reqReimport,
                      withHolderRewardRate:
                          data?.data?.eligibility?.withHolderRewardRate,
                      withAnyHoldingRewardRate:
                          data?.data?.eligibility?.withAnyHoldingRewardRate,
                      nonHolderRewardRate:
                          data?.data?.eligibility?.nonHolderRewardRate,
                      rewardType:
                          data?.data?.eligibility?.rewardType ??
                          data?.data?.basicInfo?.type,
                      showStandardBanner: true,
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
                          RewardRatesSection(
                            shareholderRate:
                                data?.data?.eligibility?.withHolderRewardRate,
                            brokerageRate: data
                                ?.data
                                ?.eligibility
                                ?.withAnyHoldingRewardRate,
                            nonShareholderRate:
                                data?.data?.eligibility?.nonHolderRewardRate,
                            isEligible: _isEligible,
                            isBrokerageEligible: _isBrokerageEligible,
                            listedOnExchange:
                                data?.data?.company?.listedOnExchange ?? true,
                            reqReimport: _reqReimport,
                            rewardType:
                                data?.data?.eligibility?.rewardType ??
                                data?.data?.basicInfo?.type,
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
                          _PayableBreakdown(
                            faceValueLabel: _serverPricing != null
                                ? _formatInr(_serverPricing!.faceAmount)
                                : (pricing?.formattedFaceValue ?? '₹ —'),
                            sharePerksDiscount: _sharePerksDiscountAmount,
                            sharePerksPercent:
                                pricing != null && pricing.percent > 0
                                ? pricing.percent
                                : null,
                            couponCode: _appliedCoupon?.code,
                            couponDiscount:
                                _serverPricing?.couponDiscount ??
                                _appliedCoupon?.discountApplied,
                            finalPayableLabel: _formattedFinalPayable,
                            formatInr: _formatInr,
                          ),
                          const SizedBox(height: 8),
                          _CouponApplyField(
                            controller: _couponController,
                            enabled: pricing != null && !_paying,
                            applying: _applyingCoupon,
                            applied: _appliedCoupon != null,
                            onApply: _applyCoupon,
                            onRemove: _removeCoupon,
                            onChanged: (_) {
                              if (_appliedCoupon != null) {
                                setState(() => _appliedCoupon = null);
                              }
                            },
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
              onPressed: _finalPayAmount == null || _paying
                  ? null
                  : _onProceedButtonTap,
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

/// Face → SharePerks discount → coupon discount → you pay.
class _PayableBreakdown extends StatelessWidget {
  const _PayableBreakdown({
    required this.faceValueLabel,
    required this.sharePerksDiscount,
    required this.sharePerksPercent,
    required this.couponCode,
    required this.couponDiscount,
    required this.finalPayableLabel,
    required this.formatInr,
  });

  final String faceValueLabel;
  final double? sharePerksDiscount;
  final double? sharePerksPercent;
  final String? couponCode;
  final double? couponDiscount;
  final String finalPayableLabel;
  final String Function(double) formatInr;

  @override
  Widget build(BuildContext context) {
    final hasCoupon = couponDiscount != null && couponDiscount! > 0;
    final hasSharePerks = sharePerksDiscount != null && sharePerksDiscount! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF6400E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x266400E0),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Card amount',
            value: faceValueLabel,
            valueColor: SharePerksColors.textPrimaryLight,
          ),
          if (hasSharePerks) ...[
            const SizedBox(height: 8),
            _BreakdownRow(
              label: sharePerksPercent != null
                  ? 'SharePerks discount (${sharePerksPercent!.toStringAsFixed(sharePerksPercent! % 1 == 0 ? 0 : 1)}% Off)'
                  : 'SharePerks discount',
              value: '- ${formatInr(sharePerksDiscount!)}',
              valueColor: SharePerksColors.accent,
              labelColor: SharePerksColors.accent,
            ),
          ],
          if (hasCoupon) ...[
            const SizedBox(height: 8),
            _BreakdownRow(
              label: couponCode != null && couponCode!.isNotEmpty
                  ? 'Coupon discount ($couponCode)'
                  : 'Coupon discount',
              value: '- ${formatInr(couponDiscount!)}',
              valueColor: SharePerksColors.success,
              labelColor: SharePerksColors.success,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: SharePerksColors.borderLight),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'You pay',
            value: finalPayableLabel,
            valueColor: SharePerksColors.primary,
            labelColor: SharePerksColors.primary,
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelColor,
    this.bold = false,
    this.large = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color? labelColor;
  final bool bold;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor ?? SharePerksColors.textSecondaryLight,
              fontSize: large ? 15 : 13,
              fontFamily: SharePerksFonts.inter,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: large ? 22 : 14,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CouponApplyField extends StatelessWidget {
  const _CouponApplyField({
    required this.controller,
    required this.enabled,
    required this.applying,
    required this.applied,
    required this.onApply,
    required this.onRemove,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool applying;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onRemove;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Have a coupon?',
          style: TextStyle(
            color: SharePerksColors.textPrimaryLight,
            fontSize: 13,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !applying && !applied,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: onChanged,
                onSubmitted: (_) {
                  if (!applied && enabled && !applying) onApply();
                },
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  prefixIcon: Icon(
                    HugeIconsSolid.couponPercent,
                    size: 18,
                    color: SharePerksColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: applied
                  ? OutlinedButton(
                      onPressed: enabled ? onRemove : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: SharePerksColors.error),
                        foregroundColor: SharePerksColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Remove'),
                    )
                  : ElevatedButton(
                      onPressed: enabled && !applying ? onApply : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SharePerksColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Apply'),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
