import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/FaqItem.dart';
import 'package:shareperks/components/WalletCard.dart';
import 'package:shareperks/components/loader/wallet_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/wallet_info_model.dart';
import 'package:shareperks/repository/services/wallet/wallet.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletInfoResponse? data;
  bool _loading = true;
  bool _error = false;

  Future<void> loadData() async {
    try {
      data = await WalletDataService.getWalletInfo();
      _error = false;
    } catch (e) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
        title: Text("Wallet"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.primary,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(18),
            child: Column(
              spacing: 20,
              children: [
                if (_loading)
                  const WalletPageShimmer()
                else if (_error)
                  _WalletLoadError(
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _error = false;
                      });
                      loadData();
                    },
                  )
                else ...[
                  BorderCard(
                    padding: EdgeInsets.all(16),
                    borderWidth: 1,
                    borderRadius: 18,
                    color: SharePerksColors.info,
                    child: Column(
                      spacing: 10,
                      children: [
                        CollapseCard(
                          initiallyCollapsed: false,
                          color: SharePerksColors.info,

                          title: Text(
                            'Earnings',
                            style: TextStyle(
                              color: SharePerksColors.info /* Information */,
                              fontSize: 16,
                              fontFamily: SharePerksFonts.albertSans,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: WalletCard(
                            amount: data?.wallet?.balance?.toDouble() ?? 0,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                SharePerksColors.info,
                              ),
                            ),
                            onPressed: () {
                              context.pushNamed(
                                RouteNames.PAYOUT_SCREEN,
                                extra: {
                                  "amount":
                                      data?.wallet?.balance.toString() ?? "0",
                                },
                              );
                            },
                            child: Text(
                              'Withdraw',
                              style: TextStyle(
                                color: const Color(0xFFF2F2F2),
                                fontSize: 14,
                                fontFamily: SharePerksFonts.inter,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          Assets.ASSETS_CARDS_TOP5PERCENTOFINVEST_PNG,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ],
                    ),
                  ),

                  BorderCard(
                    borderWidth: 1,
                    color: Color(0x3F333333),
                    padding: EdgeInsets.all(16),
                    borderRadius: 16,

                    child: CollapseCard(
                      initiallyCollapsed: false,
                      color: Color(0xFF333333),
                      title: Text(
                        'Transaction History',
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontSize: 16,
                          fontFamily: 'Albert Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.38,
                        ),
                      ),
                      child: Container(
                        child: Column(
                          children: List.generate(
                            data?.transactions.length ?? 0,
                            (index) {
                              WalletTransaction trx = data!.transactions[index];
                              return TransactionCard(
                                data: TransactionData(
                                  amount: trx.amount ?? 0,
                                  date: trx.date ?? "",
                                  time: trx.time ?? "",
                                  type: trx.isDebit ? 'DEBIT' : 'CREDIT',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  BorderCard(
                    borderWidth: 1,
                    borderRadius: 16,

                    color: SharePerksColors.primary.withAlpha(50),
                    padding: EdgeInsets.all(16),
                    child: CollapseCard(
                      color: SharePerksColors.primary,
                      initiallyCollapsed: false,
                      title: Text(
                        'FAQs',
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 16,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      child: Column(children: [FaqItem()]),
                      onChanged: (collapsed) =>
                          debugPrint('collapsed: $collapsed'),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(RouteNames.MY_REFER_LIST_SCREEN);
                    },
                    child: Image.asset(
                      Assets.ASSETS_CARDS_VIEWYOURREFERRALS_PNG,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(RouteNames.HELP_AND_SUPPORT_SCREEN);
                    },
                    child: Image.asset(
                      Assets.ASSETS_CARDS_SUPPORTCARD_PNG,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                  Copyright(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletLoadError extends StatelessWidget {
  const _WalletLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Column(
        children: [
          Text(
            'Could not load wallet.',
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
