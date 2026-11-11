import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_perks_model.dart';
import 'package:shareperks/repository/services/finance/finance.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shareholder perks for a single company, sourced from the Finance / Screener
/// API (`GET /api/company/:ticker/perks` + `/api/company/:ticker/profile`).
///
/// Replaces the old listing-service `/rewards/by-company/:companyId` flow: the
/// finance API is keyed by NSE **ticker** (e.g. `RELIANCE`), so callers must
/// pass the ticker from the reward's `basicInfo.ticker` rather than a DB id.
class CompanyViewScreen extends StatefulWidget {
  final String ticker;

  const CompanyViewScreen({super.key, required this.ticker});

  @override
  State<CompanyViewScreen> createState() => _CompanyViewScreenState();
}

class _CompanyViewScreenState extends State<CompanyViewScreen> {
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  FinanceProfile? _profile;
  FinancePerksResponse? _perks;

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = null;
      });
    }

    final ticker = widget.ticker.trim();
    if (ticker.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage = 'No ticker provided for this company.';
        });
      }
      return;
    }

    try {
      // Profile and perks are independent — fetch them in parallel so a slow
      // profile does not block the perks list (and vice versa). A missing
      // profile is non-fatal; the perks list is the primary content.
      final profileFuture = _loadProfile(ticker);
      final perksFuture = FinanceService.getCompanyPerks(ticker);
      final profile = await profileFuture;
      final perks = await perksFuture;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _perks = perks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _errorMessage = e is StateError ? e.message : null;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Profile is best-effort: a 404 for an unknown ticker should not blank the
  /// whole screen, so swallow it and let the perks list stand on its own.
  Future<FinanceProfile?> _loadProfile(String ticker) async {
    try {
      final response = await FinanceService.getProfile(ticker);
      return response.profile;
    } catch (_) {
      return null;
    }
  }

  /// Perk click destination per the Finance API docs — the SharePerks Play
  /// Store listing, where a perk is actually claimed.
  static final Uri _perkDestination = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.shareperks&hl=en_IN',
  );

  Future<void> _openPerk() async {
    await launchUrl(_perkDestination, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: const AppBackButton(),
        toolbarHeight: 40,
        title: Text(_profile?.name ?? widget.ticker.toUpperCase()),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error) {
            return _ErrorView(
              message: _errorMessage ?? 'Failed to load company perks',
              onRetry: _load,
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _CompanyHeader(profile: _profile, ticker: widget.ticker),
                  const SizedBox(height: 20),
                  _PerksBody(perks: _perks, onTap: _openPerk),
                  const SizedBox(height: 16),
                  const Copyright(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 16,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Branded header — the finance API has no banner image, so the company name,
/// sector and description stand in for it.
class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.profile, required this.ticker});

  final FinanceProfile? profile;
  final String ticker;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? ticker.toUpperCase();
    final description = profile?.description;
    final tags = [
      profile?.sector,
      profile?.industry,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6400E0), Color(0xFF8A2BE2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerksBody extends StatelessWidget {
  const _PerksBody({required this.perks, required this.onTap});

  final FinancePerksResponse? perks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final giftCards = perks?.giftCards ?? const [];
    final cashbacks = perks?.cashbacks ?? const [];
    final discountCodes = perks?.discountCodes ?? const [];

    if (giftCards.isEmpty && cashbacks.isEmpty && discountCodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
        child: Text(
          'No shareholder perks available for this company yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SharePerksColors.textSecondaryLight,
            fontSize: 13,
            fontFamily: SharePerksFonts.inter,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          if (giftCards.isNotEmpty)
            _PerkSection(
              title: 'Gift Cards',
              accent: SharePerksColors.accent,
              perks: [
                for (final g in giftCards)
                  _FinancePerkCard(
                    image: g.image,
                    title: g.title,
                    brandName: g.brandName,
                    eligibility: g.eligibility,
                    ctaLabel: 'View Gift Card',
                    onTap: onTap,
                  ),
              ],
            ),
          if (cashbacks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PerkSection(
              title: 'Cashbacks',
              accent: SharePerksColors.success,
              perks: [
                for (final c in cashbacks)
                  _FinancePerkCard(
                    image: c.image,
                    title: c.title,
                    brandName: c.brandName,
                    eligibility: c.eligibility,
                    ctaLabel: 'View Cashback',
                    onTap: onTap,
                  ),
              ],
            ),
          ],
          if (discountCodes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PerkSection(
              title: 'Discount Codes',
              accent: SharePerksColors.primary,
              perks: [
                for (final d in discountCodes)
                  _FinancePerkCard(
                    image: d.image,
                    title: d.title,
                    brandName: d.brandName,
                    eligibility: d.eligibility,
                    ctaLabel: 'View Code',
                    onTap: onTap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerkSection extends StatelessWidget {
  const _PerkSection({
    required this.title,
    required this.accent,
    required this.perks,
  });

  final String title;
  final Color accent;
  final List<Widget> perks;

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      width: double.infinity,
      borderWidth: 1,
      color: accent.withValues(alpha: 0.3),
      borderRadius: SharePerksRadii.lg,
      backgroundColor: SharePerksColors.backgroundLight,
      isGradientBackground: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            child: TitleView(
              title: Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: LabelWithForwardIcon(
                iconColor: accent,
                iconSize: 18,
                label: Text(
                  '${perks.length}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 6),
                  ...perks,
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancePerkCard extends StatelessWidget {
  const _FinancePerkCard({
    required this.image,
    required this.title,
    required this.brandName,
    required this.eligibility,
    required this.ctaLabel,
    required this.onTap,
  });

  final String? image;
  final String? title;
  final String? brandName;
  final FinanceEligibility? eligibility;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = (brandName ?? '').trim();
    final hasHolderRate =
        eligibility?.withHolderRewardRate != null &&
        eligibility!.withHolderRewardRate! > 0;

    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasHolderRate
              ? SharePerksColors.accent.withValues(alpha: 0.3)
              : SharePerksColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: ImageBuilder(
              imageUrl: imageUrl(image ?? ''),
              width: 165,
              height: 121,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                SizedBox(
                  height: 43,
                  child: Text(
                    title ?? '--',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: SharePerksColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (hasHolderRate)
                  SizedBox(
                    height: 22,
                    child: _RateBadge(
                      rate: eligibility!.withHolderRewardRate!,
                      color: SharePerksColors.accent,
                    ),
                  )
                else
                  const SizedBox(height: 22),
                if (brand.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        'Eligible via ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: SharePerksColors.textSecondaryLight,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: SharePerksColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4).copyWith(top: 0, bottom: 6),
            child: Center(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 149,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasHolderRate
                        ? SharePerksColors.accent
                        : SharePerksColors.borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasHolderRate
                          ? SharePerksColors.accent
                          : SharePerksColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      ctaLabel,
                      style: TextStyle(
                        color: hasHolderRate
                            ? SharePerksColors.backgroundLight
                            : SharePerksColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.rate, required this.color});

  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Rates come through as percentages (e.g. 100 → 100%).
    final label = rate % 1 == 0
        ? 'Shareholder ${rate.toInt()}%'
        : 'Shareholder ${rate.toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
