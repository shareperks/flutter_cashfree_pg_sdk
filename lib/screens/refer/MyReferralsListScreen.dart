import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';

class MyReferralListScreen extends StatelessWidget {
  const MyReferralListScreen({super.key});

  /// Set from referral list API: `referrals.isNotEmpty`.
  static const bool _hasReferrals = false;

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("My Referrals"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(18),
        width: MediaQuery.of(context).size.width,
        child: _hasReferrals
            ? _ReferralsListContent()
            : const _NoReferralsView(),
      ),
    );
  }
}

class _NoReferralsView extends StatelessWidget {
  const _NoReferralsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              HugeIconsSolid.chatUser,
              size: 80,
              color: SharePerksColors.accent,
            ),
            const SizedBox(height: 20),
            Text(
              'No referrals yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 18,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Share your code with friends. When they join, they will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 14,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.REFER_CODE_SCREEN);
                },
                child: const Text('Get your refer code'),
              ),
            ),
            const SizedBox(height: 16),
            const ClickToHelp(),
            const SizedBox(height: 68),
          ],
        ),
      ),
    );
  }
}

class _ReferralsListContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        CategorySearchSortBar(
          controller: TextEditingController(),
          sortBy: "",
          onSearchChanged: (e) {},
          onToggleSort: () {},
        ),
        ReferUser(
          onTap: () {
            showInfoReferSteps(context);
          },
        ),
        ReferUser(),
        ReferUser(),
        ReferUser(),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.REFER_CODE_SCREEN);
                },
                child: const Text("Refer and earn"),
              ),
              const ClickToHelp(),
            ],
          ),
        ),
      ],
    );
  }
}

class ReferUser extends StatelessWidget {
  final VoidCallback? onTap;
  const ReferUser({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.all(0),
        leading: ImageBuilder(
          imageUrl:
              "https://img.freepik.com/free-photo/young-male-posing-isolated-against-blank-studio-wall_273609-12356.jpg?semt=ais_hybrid&w=740&q=80",
          width: 48,
          height: 48,
          borderRadius: 50,
        ),
        title: Text(
          'Himanshu Goyal',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 15,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '24/03/2024',
          style: TextStyle(
            color: const Color(0xFF898989),
            fontSize: 12,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 5,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: const Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Demat not linked',
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: 1.40,
                ),
              ),
            ),
            Text(
              'Only 2 steps left!',
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                height: 1.40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showInfoReferSteps(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return SizedBox(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.9,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const <double>[0.9, 1.0],
          builder: (ctx, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
                children: [
                  ReferUser(),
                  const SizedBox(height: 20),
                  Text(
                    '3 user journey points:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.ASSETS_CARDS_REFERSTEPS_PNG,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.ASSETS_CARDS_REFERBANNERCARD_PNG,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
