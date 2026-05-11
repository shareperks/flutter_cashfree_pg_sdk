import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EligibilityCards.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/components/ReletedPerksCard.dart';
import 'package:shareperks/components/loader/GiftCardRewardShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/models/promocode_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
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
                          if (data?.data?.chimed?.claimed == false)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: MyPromoCodeView(
                                data: data?.data?.chimed,
                                onUpdateRedeemed: () {},
                              ),
                            ),
                          if (data?.data?.chimed?.claimed == true)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 10,
                              children: [
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
                              ],
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
  );
}
