import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/loader/brand_view_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/rewards_by_brand_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/key_value_list.dart';
import 'package:soui/elements/title_view.dart';

class BrandViewScreen extends StatefulWidget {
  final String brandId;
  const BrandViewScreen({super.key, required this.brandId});

  @override
  State<BrandViewScreen> createState() => _BrandViewScreenState();
}

class _BrandViewScreenState extends State<BrandViewScreen> {
  bool _loading = true;
  bool _error = false;
  RewardsByBrandResponse? _data;

  loadBrandInfo() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      _data = await ListingDataService.getRewardsByBrandId(
        brandId: widget.brandId,
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
    loadBrandInfo();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: Text("About Brand"),
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
                      'Failed to load brand',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loadBrandInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await loadBrandInfo();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ImageBuilder(
                    imageUrl: imageUrl(_data?.data?.brand?.bannerImage ?? ""),
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
                              _data?.data?.brand?.name ?? "",
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
                          _data?.data?.brand?.description ?? "",
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
                  SizedBox(height: SharePerksSpacing.lg),
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
