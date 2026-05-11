import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/FaqItem.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Wallet"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.info,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(18),
          child: Column(
            spacing: 20,
            children: [
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
                      child: Container(
                        margin: EdgeInsets.only(top: 6),
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  'Wallet Balance',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF5182FE,
                                    ) /* Information */,
                                    fontSize: 16,
                                    fontFamily: 'Albert Sans',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹ 42,600.00',
                                  style: TextStyle(
                                    color: const Color(0xFF333333),
                                    fontSize: 22,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Available to withdraw',
                                  style: TextStyle(
                                    color: SharePerksColors.accent,
                                    fontSize: 10,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w400,
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
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            SharePerksColors.info,
                          ),
                        ),
                        onPressed: () {},
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
                      children: [
                        TransactionCard(),
                        TransactionCard(),
                        TransactionCard(),
                      ],
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
                  onChanged: (collapsed) => debugPrint('collapsed: $collapsed'),
                ),
              ),
              Image.asset(
                Assets.ASSETS_CARDS_VIEWYOURREFERRALS_PNG,
                width: MediaQuery.of(context).size.width,
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
          ),
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: SharePerksColors.borderLight),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(0),

        leading: SizedBox(
          width: 10,
          child: Icon(HugeIconsSolid.arrowUp02, size: 30, color: Colors.red),
        ),
        title: Text(
          '₹ 22,200.00',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 16,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '24/03/2024',
          style: TextStyle(
            color: const Color(0xFF898989),
            fontSize: 12,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Balance: 23,450.00',
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
