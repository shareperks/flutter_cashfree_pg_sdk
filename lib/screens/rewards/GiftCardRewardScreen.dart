import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';

class GiftCardRewardScreen extends StatelessWidget {
  final String rewardId;
  const GiftCardRewardScreen({super.key, required this.rewardId});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("About Perk"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              PerkBasicInfo(),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Verify Eligibility"),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text("Claim Non-Shareholder Perk"),
                ),
              ),
              Padding(padding: const EdgeInsets.all(14.0), child: PerkTerms()),
            ],
          ),
        ),
      ),
    );
  }
}
