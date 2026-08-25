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
import 'package:shareperks/utils/support_contact.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/collaps_card.dart';
import 'package:soui/theme.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: Text("Help & Support"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(18),
          child: Column(
            spacing: 20,
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(HugeIconsSolid.search01),
                  hintText: "Search for help...",
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: SharePerksColors.inputBorderLight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
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
              GestureDetector(
                onTap: () {
                  context.pushNamed(RouteNames.HOW_SHOW_PERK_SCREEN);
                },
                child: Image.asset(
                  Assets.ASSETS_CARDS_SHOW_WE_SHOW_PERKS_PNG,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
              BorderCard(
                width: MediaQuery.of(context).size.width,
                borderWidth: 1,
                color: AppColors.accent,
                borderRadius: 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Support',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontFamily: 'Albert Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.all(0),
                        onTap: () => SupportContact.openEmail(context),
                        title: Text(
                          'Write to us',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          SupportContact.email,
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 10,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        trailing: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              width: 1,
                              color: SharePerksColors.borderLight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(HugeIconsSolid.mail02, size: 20),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.all(0),
                        onTap: () => SupportContact.openPhone(context),
                        title: Text(
                          'Call us',
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          SupportContact.phoneDisplay,
                          style: TextStyle(
                            color: const Color(0xFF898989),
                            fontSize: 10,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        trailing: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              width: 1,
                              color: SharePerksColors.borderLight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(HugeIconsSolid.call02, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: () => SupportContact.openWhatsApp(context),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      SharePerksColors.success,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        'Chat with us',
                        style: TextStyle(
                          color: const Color(0xFFF2F2F2),
                          fontSize: 14,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(HugeIconsSolid.whatsapp),
                    ],
                  ),
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
