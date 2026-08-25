import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferAndEarnCodeScreen extends StatefulWidget {
  const ReferAndEarnCodeScreen({super.key});

  @override
  State<ReferAndEarnCodeScreen> createState() => _ReferAndEarnCodeScreenState();
}

class _ReferAndEarnCodeScreenState extends State<ReferAndEarnCodeScreen> {
  @override
  void initState() {
    super.initState();
    trackAction(AnalyticsEvent.referScreenViewed, {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SharePerksColors.primary,
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Refer & Earn"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        child: Column(
          spacing: 20,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Image.asset(
                Assets.ASSETS_CARDS_REFERANDEARNSTEPS_PNG,
                width: MediaQuery.of(context).size.width,
              ),
            ),

            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(18),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x3FFFFFFF),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ReferCodeCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReferCodeCard extends StatelessWidget {
  const ReferCodeCard({super.key});

  static const _appUrl = 'https://shareperks.in';

  String _shareMessage(String code) {
    return 'Hi! 🎉 Want to save on your favorite brands just because you’re an investor?\n\n'
        'I use SharePerks to unlock exclusive discounts and rewards from brands I own. '
        'Link your investments securely and buy discounted gift cards from top brands.\n\n'
        'Download the SharePerks app now and get ₹100 Cashback: https://shareperks.in '
        'and use my referral code:\n$code';
  }

  Future<void> _shareViaWhatsApp(BuildContext context, String code) async {
    trackAction(AnalyticsEvent.referShareIntent, {'channel': 'whatsapp'});
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_shareMessage(code))}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      Fluttertoast.showToast(msg: 'Could not open WhatsApp');
    }
  }

  Future<void> _shareViaFacebook(BuildContext context, String code) async {
    trackAction(AnalyticsEvent.referShareIntent, {'channel': 'facebook'});
    final uri = Uri.https('www.facebook.com', '/sharer/sharer.php', {
      'u': _appUrl,
      'quote': _shareMessage(code),
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      Fluttertoast.showToast(msg: 'Could not open Facebook');
    }
  }

  Future<void> _shareViaSystem(String code) async {
    trackAction(AnalyticsEvent.referShareIntent, {'channel': 'system'});
    await SharePlus.instance.share(ShareParams(text: _shareMessage(code)));
  }

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      isGradientBackground: false,
      borderWidth: 1,
      borderRadius: 18,
      color: AppColors.brand.withAlpha((50)),
      child: Consumer<UserProvider>(
        builder: (context, state, child) {
          final code = state.user?.referCode ?? '';

          return Column(
            children: [
              SizedBox(height: 16),

              CopyReferCode(),

              Container(
                width: MediaQuery.of(context).size.width - 80,
                padding: EdgeInsets.all(18),

                child: ElevatedButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.MY_REFER_LIST_SCREEN);
                  },
                  child: Text(
                    'View My Referrals',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SharePerksColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              Text(
                'Let your friends know you’ve leveled up:',
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10,
                children: [
                  IconButton(
                    onPressed: code.isEmpty
                        ? null
                        : () => _shareViaWhatsApp(context, code),
                    icon: Icon(
                      HugeIconsSolid.whatsapp,
                      size: 32,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    onPressed: code.isEmpty
                        ? null
                        : () => _shareViaFacebook(context, code),
                    icon: Icon(
                      HugeIconsSolid.facebook01,
                      size: 32,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    onPressed: code.isEmpty
                        ? null
                        : () => _shareViaSystem(code),
                    icon: Icon(
                      HugeIconsSolid.share08,
                      size: 28,
                      color: SharePerksColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ClickToHelp(),
            ],
          );
        },
      ),
    );
  }
}

class CopyReferCode extends StatelessWidget {
  const CopyReferCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, state, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Container(
              width: 230,
              height: 48.26,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                shadows: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 7.80,
                    offset: Offset(0, 4.80),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                '${state.user?.referCode}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6400E0),
                  fontSize: 26.71,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                final code = state.user?.referCode;
                if (code == null || code.isEmpty) return;

                await Clipboard.setData(ClipboardData(text: code));
                trackAction(AnalyticsEvent.referCodeCopied, {
                  'referral_code': code,
                });
                Fluttertoast.showToast(
                  msg: 'Referred Code copied to clipboard',
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              },
              icon: Icon(
                HugeIconsStroke.copy01,
                color: SharePerksColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
