import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/ReletedPerksCard.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/repository/models/giftcard_detail_model.dart';
import 'package:shareperks/repository/models/promocode_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:soui/elements/SpScafold.dart';

class PromoCodeRewardScreen extends StatefulWidget {
  final String rewardId;
  const PromoCodeRewardScreen({super.key, required this.rewardId});

  @override
  State<PromoCodeRewardScreen> createState() => _PromoCodeRewardScreenState();
}

class _PromoCodeRewardScreenState extends State<PromoCodeRewardScreen> {
  bool _loading = true;
  PromocodeDetailResponse? data;
  String? _errorMessage;

  Future<void> loadData() async {
    try {
      _errorMessage = null;
      data = await RewardListingDataService.getPromocodeDetail(widget.rewardId);
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
    // TODO: implement initState
    super.initState();
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                        ).copyWith(top: 18),
                        child: Image.asset(
                          Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
                          width: MediaQuery.of(context).size.width,
                        ),
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
                          Center(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text("Verify Eligibility"),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () {},
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
