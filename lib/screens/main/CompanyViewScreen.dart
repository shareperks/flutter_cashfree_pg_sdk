import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/BrandCard.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/loader/brand_view_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/rewards_by_company_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';
import 'package:soui/theme.dart';

class CompanyViewScreen extends StatefulWidget {
  final String companyId;
  const CompanyViewScreen({super.key, required this.companyId});

  @override
  State<CompanyViewScreen> createState() => _CompanyViewScreenState();
}

class _CompanyViewScreenState extends State<CompanyViewScreen> {
  bool _loading = true;
  bool _error = false;
  RewardsByCompanyResponse? _data;

  loadCompanyInfo() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      _data = await ListingDataService.getRewardsByCompanyId(
        companyId: widget.companyId,
      );
    } catch (e) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadCompanyInfo();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: Text("About Company"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const BrandViewLoader();
          }
          if (_error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load company',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loadCompanyInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await loadCompanyInfo();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ImageBuilder(
                    imageUrl: imageUrl(_data?.data?.company?.bannerImage ?? ""),
                    width: MediaQuery.of(context).size.width,
                    height: 180,
                    alignment: Alignment.bottomCenter,
                  ),

                  Container(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Column(
                      spacing: 8,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            Text(
                              'About',
                              style: TextStyle(
                                color: const Color(0xFF333333),
                                fontSize: 18,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // ---
                            Text(
                              _data?.data?.company?.name ?? "",
                              style: TextStyle(
                                color: const Color(0xFF6400E0),
                                fontSize: 18,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _data?.data?.company?.description ?? "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  BorderCard(
                    backgroundColor: AppColors.brand,
                    color: AppColors.brand,
                    borderWidth: 1,
                    borderRadius: SharePerksRadii.lg,

                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                            bottom: 10,
                          ),
                          child: TitleView(
                            title: Text(
                              'Related Brands',
                              style: TextStyle(
                                color: SharePerksColors.primary,
                                fontSize: 18,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                context.pushNamed(RouteNames.TOP_BRANDS_SCREEN);
                              },
                              child: LabelWithForwardIcon(
                                iconColor: SharePerksColors.primary,
                                iconSize: 18,
                                label: Text(
                                  'View all',
                                  style: TextStyle(
                                    color: SharePerksColors.primary,
                                    fontSize: 13,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                SizedBox(width: 6),
                                ...List.generate(
                                  _data?.data?.brands?.length ?? 0,
                                  (index) {
                                    BrandItem brand =
                                        _data!.data!.brands![index];
                                    return BrandCard(
                                      onTap: () {
                                        context.pushNamed(
                                          RouteNames.BRAND_SCREEN,
                                          extra: {"brandId": brand.id},
                                        );
                                      },
                                      isNew: brand.isNew ?? false,
                                      title: brand.name ?? "--",
                                      ticker: brand.tickerName ?? "--",
                                      imageUrl: imageUrl(brand.image ?? ""),
                                    );
                                  },
                                ),
                                SizedBox(width: 6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: SharePerksSpacing.xl),
                  if (_data?.data?.rewards?.isNotEmpty ?? false)
                    BorderCard(
                      width: double.infinity,
                      borderWidth: 1,
                      color: SharePerksColors.accent.withValues(alpha: 0.3),
                      borderRadius: SharePerksRadii.lg,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 16,
                              left: 16,
                              right: 16,
                              bottom: 10,
                            ),
                            child: TitleView(
                              title: Text(
                                'Related Perks',
                                style: TextStyle(
                                  color: SharePerksColors.accent,
                                  fontSize: 18,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  context.pushNamed(RouteNames.CATEGORY_SCREEN);
                                },
                                child: LabelWithForwardIcon(
                                  iconColor: SharePerksColors.accent,
                                  iconSize: 18,
                                  label: Text(
                                    'View all',
                                    style: TextStyle(
                                      color: SharePerksColors.accent,
                                      fontSize: 13,
                                      fontFamily: SharePerksFonts.inter,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                spacing: 12,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 6),
                                  ...List.generate(
                                    _data?.data?.rewards?.length ?? 0,
                                    (index) {
                                      RewardItem reward =
                                          _data!.data!.rewards![index];
                                      return RewardCard(
                                        rewardId: reward.id!,
                                        type: reward.type!,
                                        typeName: reward.type,
                                        title: reward.title ?? "--",
                                        imageUrl: imageUrl(reward.image ?? ""),
                                        isEligible: reward.isEligible ?? false,
                                        eligibility: reward.companyName ?? "--",
                                      );
                                    },
                                  ),
                                  SizedBox(width: 6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  Copyright(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
