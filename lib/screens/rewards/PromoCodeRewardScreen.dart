import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EligibleRewardCard.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/ReletedPerksCard.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/journey_context.dart';
import 'package:shareperks/integrations/analytics/track_eligibility.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/models/claim_promocode_response_model.dart';
import 'package:shareperks/repository/models/promocode_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/rewards/utils/eligiblitySheet.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/title_view.dart';

class PromoCodeRewardScreen extends StatefulWidget {
  final String rewardId;
  const PromoCodeRewardScreen({super.key, required this.rewardId});

  @override
  State<PromoCodeRewardScreen> createState() => _PromoCodeRewardScreenState();
}

class _PromoCodeRewardScreenState extends State<PromoCodeRewardScreen> {
  bool _loading = true;
  bool _claiming = false;
  PromocodeDetailResponse? data;
  String? _errorMessage;

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getPromocodeDetail(widget.rewardId);
      JourneyContext.setNames(
        rewardName: data?.data?.basicInfo?.title,
        brandName: data?.data?.company?.name,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// `POST /rewards/promocode/:id/claim` — server picks the WITH_HOLDINGS
  /// vs NON_HOLDINGS pool itself based on the user's eligibility, so both
  /// the eligible and non-eligible CTAs route through this single call.
  Future<void> _claimPromocode() async {
    if (_claiming) return;

    final isEligible = data?.data?.eligibility?.isEligible ?? false;
    await trackButtonClick(
      isEligible ? 'Reveal Discount Code' : 'Claim Non-Shareholder Perk',
      {
        'reward_name': data?.data?.basicInfo?.title ?? '',
        'is_eligible': isEligible,
      },
    );
    await trackEligibility(
      perkType: 'promocode',
      rewardId: widget.rewardId,
      isEligible: isEligible,
      reason: isEligible ? 'ok' : 'not_eligible',
      source: 'reward_detail',
      brandId: data?.data?.company?.id,
    );

    setState(() => _claiming = true);
    try {
      final claim = await RewardListingDataService.claimPromocode(
        widget.rewardId,
      );
      if (!mounted) return;
      _applyClaim(claim);
      await trackAction(AnalyticsEvent.promocodeRevealed, {
        'reward_id': widget.rewardId,
        'already_claimed': claim.alreadyClaimed == true,
      });
      Fluttertoast.cancel();
      Fluttertoast.showToast(
        msg: claim.alreadyClaimed == true
            ? 'You already have this code.'
            : 'Discount code unlocked!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      await trackAction(AnalyticsEvent.promocodeRevealBlocked, {
        'reason': _readableError(e),
      });
      Fluttertoast.cancel();
      Fluttertoast.showToast(
        msg: _readableError(e),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _applyClaim(ClaimPromocodeResponse claim) {
    final detail = data?.data;
    if (detail == null) return;
    final chimed = detail.chimed ?? PromocodeChimed();
    chimed
      ..code = claim.code ?? chimed.code
      ..claimedId = claim.claimedId ?? chimed.claimedId
      ..isEligible = claim.isEligible ?? chimed.isEligible
      ..chimedAt = claim.assignedAt ?? chimed.chimedAt
      // Newly allocated code is unredeemed; the existing redeem-toggle UI
      // takes over from here.
      ..claimed = chimed.claimed ?? false;
    detail.chimed = chimed;
    setState(() {});
  }

  String _readableError(Object e) {
    if (e is StateError) return e.message;
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return 'Could not claim discount code. Please try again.';
  }

  bool get _hasClaimedCode {
    final c = data?.data?.chimed;
    return c != null && (c.claimedId?.isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    if (JourneyContext.currentJourneyId == null) {
      JourneyContext.startJourney(
        rewardId: widget.rewardId,
        perkType: 'promocode',
      );
    }
    trackAction(AnalyticsEvent.promocodePerkViewed, {
      'reward_id': widget.rewardId,
      'source': 'reward_detail',
    });
    loadData();
  }

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
      body: _loading
          ? const GiftCardRewardShimmer()
          : _errorMessage != null
          ? Center(
              child: Text('Failed to load perk.', textAlign: TextAlign.center),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await loadData();
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (data?.data?.eligibility?.isEligible ?? false)
                      EligibleRewardCard(
                        rewardRatePercent:
                            data?.data?.eligibility?.withHolderRewardRate,
                        rewardType: data?.data?.eligibility?.rewardType ??
                            data?.data?.basicInfo?.type,
                      ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          PerkBasicInfo(
                            onTickerTap: () {
                              context.pushNamed(
                                RouteNames.COMPANY_SCREEN,
                                extra: {"companyId": data?.data?.company?.id},
                              );
                            },
                            data: PerkBasicInfoData(
                              imageUrl:
                                  data?.data?.basicInfo?.bannerImage ?? '',
                              typeLabel: data?.data?.basicInfo?.type ?? '',
                              title: data?.data?.basicInfo?.title ?? '',
                              tickerValue: data?.data?.basicInfo?.ticker ?? '',
                              perkIdValue: data?.data?.basicInfo?.perkId ?? '',
                              detailsBody:
                                  data?.data?.content?.description ?? '',
                              eligibility: EligibilityCardsData(
                                holdingPeriodDays:
                                    data?.data?.eligibility?.days ?? 0,
                                sharesRequired:
                                    data?.data?.eligibility?.quantity ?? 0,
                                // Not in this API response; keep a sane default.
                                renewEveryDays: 0,
                              ),
                            ),
                          ),
                          RewardRatesSection(
                            shareholderRate:
                                data?.data?.eligibility?.withHolderRewardRate,
                            nonShareholderRate:
                                data?.data?.eligibility?.nonHolderRewardRate,
                            isEligible:
                                data?.data?.eligibility?.isEligible ?? false,
                            rewardType: data?.data?.eligibility?.rewardType ??
                                data?.data?.basicInfo?.type,
                          ),
                          if (_hasClaimedCode)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: MyPromoCodeView(
                                data: data?.data?.chimed,
                                onUpdateRedeemed: () {},
                              ),
                            )
                          else
                            _ClaimPromoCodeCta(
                              isEligible:
                                  data?.data?.eligibility?.isEligible ?? false,
                              loading: _claiming,
                              onPressed: _claimPromocode,
                            ),

                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: PerkTerms(
                              onViewAll: () {
                                context.pushNamed(
                                  RouteNames.REWARD_TERM_VIEW_SCREEN,
                                  extra: {"contentId": data?.data?.content?.id},
                                );
                              },
                              termsAndConditions:
                                  data?.data?.content?.termsAndConditions ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((data?.data?.relatedPerks ?? []).isNotEmpty)
                      RelatedPerksCard(
                        items: data?.data?.relatedPerks ?? [],
                        title: "Perks from ${data?.data?.company?.name}",
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MyPromoCodeView extends StatefulWidget {
  VoidCallback? onUpdateRedeemed;
  MyPromoCodeView({super.key, required this.data, this.onUpdateRedeemed});

  final PromocodeChimed? data;

  @override
  State<MyPromoCodeView> createState() => _MyPromoCodeViewState();
}

class _MyPromoCodeViewState extends State<MyPromoCodeView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Discount Code',
              style: TextStyle(
                color: SharePerksColors.primary,
                fontSize: 16,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              HugeIconsSolid.copy01,
              size: 16,
              color: SharePerksColors.primary,
            ),
          ],
        ),
        DottedBorder(
          options: RectDottedBorderOptions(
            dashPattern: [10, 5],
            strokeWidth: 1,
            color: SharePerksColors.primary,
            padding: EdgeInsets.all(15),
            strokeCap: StrokeCap.round,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Text(
                widget.data?.code ?? "--",
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 23.40,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LabelWithForwardIcon(
              iconSize: 17,
              iconColor: SharePerksColors.primary,
              label: Text(
                'How to redeem',
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.data?.claimedId != null)
              GestureDetector(
                onTap: () async {
                  try {
                    if (widget.data?.claimed != null) {
                      setState(() {
                        widget.data?.claimed = !(widget.data!.claimed ?? false);
                      });
                    }
                    await RewardListingDataService.togglePromocodeRedeemed(
                      widget.data?.claimedId ?? "",
                    );
                    widget.onUpdateRedeemed?.call();
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Failed to update redeemed");
                    print(e);
                  }
                },
                child: Text(
                  (widget.data?.claimed == false)
                      ? 'Mark as redeemed'
                      : "Mark not redeemed",
                  style: TextStyle(
                    color: SharePerksColors.primary,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

void showClaimedPromoCodeSheet(
  BuildContext context, {
  PromocodeChimed? data,
  String? name,
  String? subtitle,
  String? rewardId,
  Function()? onUpdateRedeemed,
}) {
  final restoreScreen = trackBottomSheet('promocode_claimed_sheet', {
    'reward_name': ?name,
  });
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                spacing: 4,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name',
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 20,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$subtitle',
                    style: TextStyle(
                      color: const Color(0xFF898989),
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              MyPromoCodeView(data: data, onUpdateRedeemed: onUpdateRedeemed),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(restoreScreen);
}

/// CTA shown on `PromoCodeRewardScreen` until the user has a claimed code.
/// Eligible users see "Reveal Discount Code" (primary). Non-eligible users
/// see a primary "Claim Non-Shareholder Perk" with a soft heads-up that the
/// non-eligible pool is being used. Either CTA hits the same
/// `POST /rewards/promocode/:id/claim` endpoint — the server picks the
/// pool.
class _ClaimPromoCodeCta extends StatelessWidget {
  const _ClaimPromoCodeCta({
    required this.isEligible,
    required this.loading,
    required this.onPressed,
  });

  final bool isEligible;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isEligible
        ? 'Reveal Discount Code'
        : 'Claim Non-Shareholder Perk';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: loading ? null : onPressed,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(label),
          ),
          if (!isEligible)
            Text(
              "You're not eligible for the shareholder pool, but you can still claim a non-shareholder code.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}
