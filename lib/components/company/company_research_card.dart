import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

/// Home-screen entry point into company research.
///
/// Opens the search screen rather than a fixed company: the details page is
/// addressed by NSE symbol / BSE code and the home payload carries neither.
class CompanyResearchCard extends StatelessWidget {
  const CompanyResearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(CompanyRadii.lg),
        onTap: () => context.pushNamed(RouteNames.COMPANY_SEARCH_SCREEN),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SharePerksSpacing.md),
          decoration: BoxDecoration(
            color: SharePerksColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(CompanyRadii.lg),
            border: Border.all(
              color: SharePerksColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: SharePerksColors.primary,
                  borderRadius: BorderRadius.circular(CompanyRadii.md),
                ),
                child: const Icon(
                  HugeIconsSolid.analyticsUp,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: SharePerksSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Financials',
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontSize: 14,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search any listed company — metrics, results, peers',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 11,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                HugeIconsSolid.arrowRight01,
                size: 16,
                color: SharePerksColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
