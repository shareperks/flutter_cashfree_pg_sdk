import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/FaqItem.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class FAQsScreen extends StatelessWidget {
  const FAQsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("FAQs"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(18),
          width: MediaQuery.of(context).size.width,
          child: Column(
            spacing: 10,
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(HugeIconsSolid.search01),
                  hintText: "Search for help...",
                ),
              ),
              TabButtons(
                layoutWidthInset: 44,
                items: ["Perks", "How to claim", "Benefit", "Referrals"],
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  spacing: 5,
                  children: [
                    FaqItem(showBorder: true),
                    FaqItem(showBorder: true),
                    FaqItem(showBorder: true),
                    FaqItem(showBorder: true),
                    FaqItem(showBorder: true),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Image.asset(
                Assets.ASSETS_CARDS_SHOW_WE_SHOW_PERKS_PNG,
                width: MediaQuery.of(context).size.width,
              ),
              SizedBox(height: 10),
              ClickToHelp(),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
