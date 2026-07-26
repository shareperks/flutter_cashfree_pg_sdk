import 'package:flutter/material.dart';
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
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/rewards/utils/eligiblitySheet.dart';
import 'package:shareperks/screens/rewards/utils/reward_eligibility.dart';
import 'package:soui/elements/SpScafold.dart';

class GiftCardRewardScreen extends StatefulWidget {
  final String rewardId;
  const GiftCardRewardScreen({super.key, required this.rewardId});

  @override
  State<GiftCardRewardScreen> createState() => _GiftCardRewardScreenState();
}

class _GiftCardRewardScreenState extends State<GiftCardRewardScreen> {
  bool _loading = true;
  GiftcardDetailResponse? data;
  String? _errorMessage;

  bool get _isEligible => data?.data?.eligibility?.isEligible ?? false;
  bool get _isBrokerageEligible =>
      data?.data?.eligibility?.isBrokerageEligible ?? false;
  bool get _reqReimport =>
      data?.data?.eligibility?.isBrokerConnected?.reqReimport == true;
  bool get _listedOnExchange => data?.data?.company?.listedOnExchange ?? true;

  RewardEligibilityTier get _tier => resolveRewardTier(
    isEligible: _isEligible,
    isBrokerageEligible: _isBrokerageEligible,
    reqReimport: _reqReimport,
  );

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getGiftcardDetail(widget.rewardId);
      JourneyContext.setNames(
        rewardName: data?.data?.basicInfo?.title,
        brandName: data?.data?.company?.name,
      );
      trackAction(AnalyticsEvent.giftcardPerkViewed, {
        'reward_id': widget.rewardId,
        'gift_card_name': data?.data?.basicInfo?.title ?? '',
        'brand_name': data?.data?.company?.name ?? '',
        'is_eligible': _isEligible,
        'is_brokerage_eligible': _isBrokerageEligible,
        'source': 'reward_detail',
      });
      await _trackEligibilityFromData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (JourneyContext.currentJourneyId == null) {
      JourneyContext.startJourney(
        rewardId: widget.rewardId,
        perkType: 'giftcard',
      );
    }
    loadData();
  }

  Future<void> _trackEligibilityFromData() async {
    final eligibility = data?.data?.eligibility;
    if (eligibility == null) return;
    final isEligible = eligibility.isEligible ?? false;
    final isBrokerageEligible = eligibility.isBrokerageEligible ?? false;
    String? reason;
    if (_reqReimport) {
      reason = 'req_reimport';
    } else if (isEligible) {
      reason = 'ok';
    } else if (isBrokerageEligible) {
      reason = 'brokerage_eligible';
    } else if (eligibility.isBrokerConnected?.connected != true) {
      reason = 'no_holdings';
    } else {
      reason = 'not_eligible';
    }
    await trackEligibility(
      perkType: 'giftcard',
      rewardId: widget.rewardId,
      isEligible: isEligible,
      isBrokerageEligible: isBrokerageEligible,
      reason: reason,
      source: 'reward_detail',
      brandId: data?.data?.company?.id,
    );
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
                              onPressed: () {
                                trackButtonClick('Verify Eligibility', {
                                  'gift_card_name':
                                      data?.data?.basicInfo?.title ?? '',
                                  'is_eligible': _isEligible,
                                  'is_brokerage_eligible': _isBrokerageEligible,
                                });
                                if (!(data
                                            ?.data
                                            ?.eligibility
                                            ?.isBrokerConnected
                                            ?.connected ??
                                        false) ||
                                    _reqReimport) {
                                  noDematAccountConnectSheet(context);
                                  return;
                                }
                                // Brokerage / fully eligible: go claim with API tiers.
                                if (_tier != RewardEligibilityTier.nonHolder) {
                                  context.pushNamed(
                                    RouteNames.GIFTCARD_AMOUNT_SCREEN,
                                    extra: {
                                      "rewardId": widget.rewardId,
                                      "isEligible": _isEligible.toString(),
                                      "isBrokerageEligible":
                                          _isBrokerageEligible.toString(),
                                      "forceNonHolder": "false",
                                    },
                                  );
                                  return;
                                }
                                eligibilitySheet(
                                  context,
                                  isEligible: _isEligible,
                                  isBrokerageEligible: _isBrokerageEligible,
                                  rewardId: widget.rewardId,
                                  shareholderRate: data
                                      ?.data
                                      ?.eligibility
                                      ?.withHolderRewardRate,
                                  brokerageRate: data
                                      ?.data
                                      ?.eligibility
                                      ?.withAnyHoldingRewardRate,
                                  nonShareholderRate: data
                                      ?.data
                                      ?.eligibility
                                      ?.nonHolderRewardRate,
                                  listedOnExchange: _listedOnExchange,
                                  reqReimport: _reqReimport,
                                  rewardType:
                                      data?.data?.eligibility?.rewardType ??
                                      data?.data?.basicInfo?.type,
                                );
                              },
                              child: Text(switch (_tier) {
                                RewardEligibilityTier.fullyEligible =>
                                  _listedOnExchange
                                      ? 'Claim Shareholder Perk'
                                      : 'Claim Brokerage Perk',
                                RewardEligibilityTier.brokerageEligible =>
                                  'Claim Brokerage Perk',
                                RewardEligibilityTier.nonHolder =>
                                  'Verify Eligibility',
                              }),
                            ),
                          ),
                          if (_tier != RewardEligibilityTier.fullyEligible)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  trackButtonClick(
                                    'Claim Non-Shareholder Perk',
                                    {
                                      'gift_card_name':
                                          data?.data?.basicInfo?.title ?? '',
                                      'is_eligible': false,
                                      'is_brokerage_eligible': false,
                                      'force_non_holder': true,
                                    },
                                  );
                                  context.pushNamed(
                                    RouteNames.GIFTCARD_AMOUNT_SCREEN,
                                    extra: {
                                      "rewardId": widget.rewardId,
                                      "isEligible": "false",
                                      "isBrokerageEligible": "false",
                                      "forceNonHolder": "true",
                                    },
                                  );
                                },
                                child: Text("Claim Non-Shareholder Perk"),
                              ),
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
