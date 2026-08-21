import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EligibleRewardCard.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/ReletedPerksCard.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/journey_context.dart';
import 'package:shareperks/integrations/analytics/track_eligibility.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/rewards/utils/reward_eligibility.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:url_launcher/url_launcher.dart';

class CashBackRewardScreen extends StatefulWidget {
  final String rewardId;
  const CashBackRewardScreen({super.key, required this.rewardId});

  @override
  State<CashBackRewardScreen> createState() => _CashBackRewardScreenState();
}

class _CashBackRewardScreenState extends State<CashBackRewardScreen> {
  bool _loading = true;
  bool _opening = false;
  CashbackDetailResponse? data;
  String? _errorMessage;

  bool get _isEligible => data?.data?.eligibility?.isEligible ?? false;
  bool get _isBrokerageEligible =>
      data?.data?.eligibility?.isBrokerageEligible ?? false;
  bool get _reqReimport =>
      data?.data?.eligibility?.isBrokerConnected?.reqReimport == true;
  bool get _listedOnExchange =>
      data?.data?.company?.listedOnExchange ?? true;

  RewardEligibilityTier get _tier => resolveRewardTier(
    isEligible: _isEligible,
    isBrokerageEligible: _isBrokerageEligible,
    reqReimport: _reqReimport,
  );

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getCashbackDetail(widget.rewardId);
      JourneyContext.setNames(
        rewardName: data?.data?.basicInfo?.title,
        brandName: data?.data?.company?.name,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Mints an affiliate tracking link via `GET /cashback/tracking-link` and
  /// hands it to the OS browser. Shareholder vs non-shareholder pool is
  /// resolved server-side, so both CTAs go through the same call.
  Future<void> _openTrackingLink() async {
    if (_opening) return;

    final label = switch (_tier) {
      RewardEligibilityTier.fullyEligible => 'Shop Now & Earn Cashback',
      RewardEligibilityTier.brokerageEligible =>
        'Shop Now at Brokerage Rate',
      RewardEligibilityTier.nonHolder => 'Verify Eligibility',
    };
    await trackButtonClick(label, {
      'reward_name': data?.data?.basicInfo?.title ?? '',
      'is_eligible': _isEligible,
      'is_brokerage_eligible': _isBrokerageEligible,
    });
    await trackEligibility(
      perkType: 'cashback',
      rewardId: widget.rewardId,
      isEligible: _isEligible,
      isBrokerageEligible: _isBrokerageEligible,
      reason: switch (_tier) {
        RewardEligibilityTier.fullyEligible => 'ok',
        RewardEligibilityTier.brokerageEligible => 'brokerage_eligible',
        RewardEligibilityTier.nonHolder => _reqReimport
            ? 'req_reimport'
            : 'not_eligible',
      },
      source: 'reward_detail',
      brandId: data?.data?.company?.id,
    );
    trackAction(AnalyticsEvent.cashbackClaimStarted, {
      'reward_id': widget.rewardId,
    });

    setState(() => _opening = true);
    try {
      final tracking = await RewardListingDataService.getCashbackTrackingLink(
        widget.rewardId,
      );
      if (!mounted) return;

      final uri = Uri.tryParse(tracking.link);
      if (uri == null) {
        throw StateError('Server returned an invalid tracking URL.');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open the merchant page.');
      }
      trackAction(AnalyticsEvent.cashbackClaimCompleted, {
        'reward_id': widget.rewardId,
      });
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.cancel();
      Fluttertoast.showToast(
        msg: _readableError(e),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  String _readableError(Object e) {
    if (e is StateError) return e.message;
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return 'Could not open the merchant page. Please try again.';
  }

  Widget _tierBanner() {
    final rewardType =
        data?.data?.eligibility?.rewardType ?? data?.data?.basicInfo?.type;
    return RewardEligibilityBanner(
      isEligible: _isEligible,
      isBrokerageEligible: _isBrokerageEligible,
      listedOnExchange: _listedOnExchange,
      reqReimport: _reqReimport,
      withHolderRewardRate: data?.data?.eligibility?.withHolderRewardRate,
      withAnyHoldingRewardRate:
          data?.data?.eligibility?.withAnyHoldingRewardRate,
      nonHolderRewardRate: data?.data?.eligibility?.nonHolderRewardRate,
      rewardType: rewardType,
      showStandardBanner: true,
    );
  }

  @override
  void initState() {
    super.initState();
    if (JourneyContext.currentJourneyId == null) {
      JourneyContext.startJourney(
        rewardId: widget.rewardId,
        perkType: 'cashback',
      );
    }
    trackAction(AnalyticsEvent.cashbackPerkViewed, {
      'reward_id': widget.rewardId,
      'source': 'reward_detail',
    });
    trackAction(AnalyticsEvent.viewContent, {
      'label': 'View Content',
      'content_type': 'cashback',
      'perk_type': 'cashback',
      'item_id': widget.rewardId,
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
                    _tierBanner(),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          PerkBasicInfo(
                            onCompanyTap: () {
                              context.pushNamed(
                                RouteNames.COMPANY_SCREEN,
                                extra: {"companyId": data?.data?.company?.id},
                              );
                            },
                            onBrandTap: () {
                              final brandId = data?.data?.brand?.id;
                              if (brandId == null || brandId.isEmpty) return;
                              context.pushNamed(
                                RouteNames.BRAND_SCREEN,
                                extra: {"brandId": brandId},
                              );
                            },
                            data: PerkBasicInfoData(
                              imageUrl:
                                  data?.data?.basicInfo?.bannerImage ?? '',
                              typeLabel: data?.data?.basicInfo?.type ?? '',
                              title: data?.data?.basicInfo?.title ?? '',
                              companyValue: data?.data?.company?.name ?? '',
                              brandValue: data?.data?.brand?.name ?? '',
                              detailsBody:
                                  data?.data?.content?.description ?? '',
                              eligibility:
                                  (_listedOnExchange &&
                                      RewardRateUi.hasAnyRate(
                                        data
                                            ?.data
                                            ?.eligibility
                                            ?.withHolderRewardRate,
                                        data
                                            ?.data
                                            ?.eligibility
                                            ?.withAnyHoldingRewardRate,
                                        data
                                            ?.data
                                            ?.eligibility
                                            ?.nonHolderRewardRate,
                                      ))
                                  ? EligibilityCardsData(
                                      holdingPeriodDays:
                                          data?.data?.eligibility?.days ?? 0,
                                      sharesRequired:
                                          data?.data?.eligibility?.quantity ??
                                          0,
                                      // Not in this API response; keep a sane default.
                                      renewEveryDays: 0,
                                    )
                                  : null,
                            ),
                          ),
                          if (RewardRateUi.hasAnyRate(
                            data?.data?.eligibility?.withHolderRewardRate,
                            data?.data?.eligibility?.withAnyHoldingRewardRate,
                            data?.data?.eligibility?.nonHolderRewardRate,
                          ))
                            RewardRatesSection(
                              shareholderRate: data
                                  ?.data
                                  ?.eligibility
                                  ?.withHolderRewardRate,
                              brokerageRate: data
                                  ?.data
                                  ?.eligibility
                                  ?.withAnyHoldingRewardRate,
                              nonShareholderRate:
                                  data?.data?.eligibility?.nonHolderRewardRate,
                              isEligible: _isEligible,
                              isBrokerageEligible: _isBrokerageEligible,
                              listedOnExchange: _listedOnExchange,
                              reqReimport: _reqReimport,
                              rewardType:
                                  data?.data?.eligibility?.rewardType ??
                                  data?.data?.basicInfo?.type,
                            ),
                          Center(
                            child: ElevatedButton(
                              onPressed: _opening ? null : _openTrackingLink,
                              child: _opening
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      switch (_tier) {
                                        RewardEligibilityTier.fullyEligible =>
                                          'Shop Now & Earn Cashback',
                                        RewardEligibilityTier
                                            .brokerageEligible =>
                                          'Shop Now at Brokerage Rate',
                                        RewardEligibilityTier.nonHolder =>
                                          'Verify Eligibility',
                                      },
                                    ),
                            ),
                          ),
                          if (_tier != RewardEligibilityTier.fullyEligible)
                            Center(
                              child: TextButton(
                                onPressed: _opening ? null : _openTrackingLink,
                                child: const Text("Claim Non-Shareholder Perk"),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: PerkTerms(
                              onViewAll: () {
                                context.pushNamed(
                                  RouteNames.REWARD_TERM_VIEW_SCREEN,
                                  extra: {
                                    "contentId": data?.data?.content?.id,
                                  },
                                );
                              },
                              termsAndConditions:
                                  data?.data?.content?.termsAndConditions ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    PerkRelatedSection(
                      relatedPerks: data?.data?.relatedPerks ?? const [],
                      categoryId: data?.data?.category?.id,
                      currentRewardId: widget.rewardId,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
