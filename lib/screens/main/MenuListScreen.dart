import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/ProfileCard.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/auth_service.dart';
import 'package:shareperks/repository/services/listing/referral.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/gredent_list.dart';
import 'package:soui/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  int _referralCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReferralCount());
  }

  Future<void> _loadReferralCount() async {
    try {
      final referrals = await ReferralListingService.getAllReferrals();
      if (!mounted) return;
      setState(() => _referralCount = referrals.length);
    } catch (_) {
      // Best-effort badge — keep previous count on error.
    }
  }

  Future<void> _openReferrals() async {
    await context.pushNamed(RouteNames.REFER_CODE_SCREEN);
    if (!mounted) return;
    // unawaited(_loadReferralCount());
  }

  Future<void> _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await AuthService.logout();
    if (!context.mounted) return;

    context.read<UserProvider>().clearUser();
    context.read<HomeDataProvider>().setHomeData(null);
    context.goNamed(RouteNames.LANDING_SCREEN);
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        toolbarHeight: 40,
        leading: AppBackButton(),
        title: Text("Profile"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(18),
          child: Column(
            children: [
              ProfileCard(),
              SizedBox(height: 20),
              ListView(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  GredentListTile(
                    leading: Icon(
                      HugeIconsSolid.rupee,
                      size: 17,
                      color: Colors.black,
                    ),

                    title: Text(
                      'My Earnings',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    color: AppColors.accent,
                    onTap: () {
                      context.pushNamed(RouteNames.EARNING_SCREEN);
                    },
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // GredentListTile(
                  //   leading: Icon(
                  //     HugeIconsSolid.mailOpen01,
                  //     size: 17,
                  //     color: Colors.black,
                  //   ),
                  //   title: Text(
                  //     'My Email Coupons',
                  //     style: TextStyle(
                  //       color: const Color(0xFF333333),
                  //       fontSize: 12,
                  //       fontFamily: SharePerksFonts.inter,
                  //       fontWeight: FontWeight.w700,
                  //     ),
                  //   ),
                  //   color: AppColors.accent,
                  //   onTap: () {
                  //     context.pushNamed(RouteNames.MY_EMAIL_COUPONS_SCREEN);
                  //   },
                  //   style: GredentListTileStyle(
                  //     contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  //     decoration: BoxDecoration(
                  //       border: Border(
                  //         bottom: BorderSide(
                  //           color: AppColors.neutral700.withAlpha(40),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  GredentListTile(
                    leading: Icon(
                      HugeIconsSolid.share01,
                      size: 17,
                      color: Colors.black,
                    ),
                    title: Text(
                      'Refer & Earn',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    color: AppColors.accent,
                    onTap: _openReferrals,
                    trailing: _referralCount > 0
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: SharePerksColors.accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: Text(
                                  _referralCount > 99
                                      ? '99+'
                                      : '$_referralCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  GredentListTile(
                    leading: Icon(
                      HugeIconsStroke.helpCircle,
                      size: 17,
                      color: Colors.black,
                    ),
                    title: Text(
                      'FAQs',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    onTap: () async {
                      context.pushNamed(RouteNames.FAQS_SCREEN);
                    },
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  GredentListTile(
                    leading: Icon(
                      HugeIconsStroke.setting07,
                      size: 17,
                      color: Colors.black,
                    ),
                    title: Text(
                      'Settings & Security',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    onTap: () {
                      context.pushNamed(RouteNames.SETTINGS_SCREEN);
                    },
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GredentListTile(
                    leading: Icon(
                      HugeIconsStroke.gift,
                      size: 17,
                      color: Colors.black,
                    ),
                    title: Text(
                      'Request a Perk',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    onTap: () {
                      context.pushNamed(RouteNames.REQUEST_PERK_SCREEN);
                    },
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  GredentListTile(
                    leading: Icon(
                      HugeIconsStroke.lockKey,
                      size: 17,
                      color: Colors.black,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    onTap: () async {
                      launchUrl(
                        Uri.parse("https://www.shareperks.in/b2c/policy"),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    style: GredentListTileStyle(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral700.withAlpha(40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    onTap: () => _onLogout(context),
                    leading: Icon(HugeIconsStroke.logoutCircle01, size: 17),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: const Color(0xFF898989),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
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
            ],
          ),
        ),
      ),
    );
  }
}
