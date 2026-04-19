import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';

class LinkDematInfoScreen extends StatelessWidget {
  const LinkDematInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 10,
          children: [
            SizedBox(height: 60),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [Icon(HugeIconsSolid.arrowLeft02), Text('Back')],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Image.asset(
              Assets.ASSETS_BOX_PNG,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Connect your brokerage',
                    style: TextStyle(
                      color: const Color(0xFF6400E0),
                      fontSize: 22,
                      fontFamily: 'Albert Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.27,
                    ),
                  ),
                  TextSpan(
                    text: '\nto browse curated perks',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 22,
                      fontFamily: 'Albert Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.27,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Get started by linking your brokerage account via ',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                  TextSpan(
                    text: 'Plaid',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.33,
                    ),
                  ),
                  TextSpan(
                    text:
                        '. This allows us to verify your ownership and show you tailored benefits.\n',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                  TextSpan(
                    text: 'See how we handle your data.',
                    style: TextStyle(
                      color: const Color(0xFF5182FE) /* Information */,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF5182FE),
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Link Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SharePerksColors.primary,
              ),
            ),
            Text(
              'Read-only access. We can’t trade or move funds.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
