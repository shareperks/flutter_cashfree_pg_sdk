import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Notifications"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
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
          ],
        ),
      ),
    );
  }
}
