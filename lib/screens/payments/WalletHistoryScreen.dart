import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/WalletCard.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class WalletHistoryScreen extends StatelessWidget {
  const WalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Wallet History"),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.borderDark,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          spacing: 10,
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(HugeIconsSolid.search01),
                hint: Text("Search"),
              ),
            ),
            TabButtons(
              selectedIndex: 0,
              onTap: (index) {},
              layoutWidthInset: 44,
              items: ["All", "Withdrawals", "Credits"],
            ),
            Column(
              children: [
                // TransactionCard(),
                // TransactionCard(),
                // TransactionCard(),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: ClickToHelp(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
