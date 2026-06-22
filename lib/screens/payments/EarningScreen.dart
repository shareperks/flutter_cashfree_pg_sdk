import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/loader/wallet_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/wallet_info_model.dart';
import 'package:shareperks/repository/services/wallet/wallet.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  WalletInfoResponse? data;
  bool _loading = true;
  bool _error = false;

  Future<void> loadData() async {
    try {
      data = await WalletDataService.getWalletInfo();
      _error = false;
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _error = false;
    });
    loadData();
  }

  WalletSummary? get _wallet => data?.wallet;

  /// Matches prior static mock style (e.g. `42,600.00`).
  static String _formatAmount(double? value) {
    return '${value?.toStringAsFixed(2)}';
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Earnings"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.info,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: _loading
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: WalletPageShimmer(),
              ),
            )
          : _error
          ? Center(child: _EarningLoadError(onRetry: _retryLoad))
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: const Color(0x3F5182FE),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Text(
                                'Withdrawable Earnings',
                                style: TextStyle(
                                  color: const Color(
                                    0xFF5182FE,
                                  ) /* Information */,
                                  fontSize: 16,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatAmount(_wallet?.balance),
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 22,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                  height: 1.27,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF5283FE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                HugeIconsSolid.wallet01,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color: SharePerksColors.borderLight,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          'Pending earnings',
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          '₹ ${_formatAmount(_wallet?.totalPendingAmount)}',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 14,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color: SharePerksColors.borderLight,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          'Lifetime earnings',
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          '₹ ${_formatAmount(_wallet?.totalLifeEarn)}',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 14,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Image.asset(
                      Assets.ASSETS_CARDS_TOP5PERCENTOFINVEST_PNG,
                      width: MediaQuery.of(context).size.width,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BorderCard(
                          color: SharePerksColors.success,
                          width: (MediaQuery.of(context).size.width - 40) / 2,
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 15,
                          ),
                          borderWidth: 1,
                          borderRadius: 16,
                          child: Column(
                            spacing: 5,
                            children: [
                              Image.asset(
                                Assets.ASSETS_ICONS_BENEFITS_PNG,
                                width: 90,
                              ),
                              Text(
                                'Total Earnings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF898989),
                                  fontSize: 11.20,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹ ${_formatAmount(_wallet?.totalCashbackEarn)}',
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 13,
                                  fontFamily: SharePerksFonts.inter,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        BorderCard(
                          color: SharePerksColors.accent,
                          width: (MediaQuery.of(context).size.width - 40) / 2,
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 15,
                          ),
                          borderWidth: 1,
                          borderRadius: 16,
                          child: Column(
                            spacing: 5,
                            children: [
                              Image.asset(
                                Assets.ASSETS_ICONS_REFERRALS_PNG,
                                width: 90,
                              ),
                              Text(
                                'Total Earnings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF898989),
                                  fontSize: 11.20,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹ ${_formatAmount(_wallet?.totalReferEarn)}',
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 13,
                                  fontFamily: SharePerksFonts.inter,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.WALLET_HISTORY_SCREEN);
                      },
                      child: Text("View Transaction History"),
                    ),
                    SizedBox(height: 20),
                    ClickToHelp(),
                    Copyright(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EarningLoadError extends StatelessWidget {
  const _EarningLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load earnings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SharePerksFonts.albertSans,
              fontSize: 16,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
