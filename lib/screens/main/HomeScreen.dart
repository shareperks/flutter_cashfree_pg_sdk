import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BottomNavBar.dart';
import 'package:shareperks/components/BrandCard.dart';
import 'package:shareperks/components/CategoryView.dart';
import 'package:shareperks/components/CopyRight.dart';
import 'package:shareperks/components/OptionView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/WelcomeCard.dart';
import 'package:shareperks/components/holding/ImportProgressSection.dart';
import 'package:shareperks/components/loader/homepageLoader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/feature/VotingBrands.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/repository/services/notification/notification.service.dart';
import 'package:shareperks/repository/services/holding/holding.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';
import 'package:soui/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _isError = false;
  HomeDataModel? data;

  /// Bell badge count. Refreshed on initState and again whenever we return
  /// from `NotificationsScreen` (mark-all-read / delete may have changed it).
  int _unreadCount = 0;

  /// Last `HomeDataProvider.reloadVersion` we acted on. We re-fetch whenever
  /// the provider's version advances past this — set elsewhere in the app
  /// (e.g. after the user changes their primary demat in MyHoldingScreen).
  int _lastSeenReloadVersion = 0;
  HomeDataProvider? _homeProvider;
  bool _refreshingHoldings = false;

  Future loadData() async {
    setState(() {
      _isError = false;
      _loading = true;
    });
    try {
      data = await ListingDataService.getHomeData();
    } catch (e) {
      _isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Refreshes the bell badge from `GET /notifications/unread-count`.
  /// Best-effort — the service swallows transport errors and returns 0.
  Future<void> _refreshUnreadCount() async {
    final result = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = result.unreadCount);
  }

  Future<void> _openNotifications() async {
    await context.pushNamed(RouteNames.NOTIFICATION_SCREEN);
    if (!mounted) return;
    // The user may have read / deleted notifications while away — re-pull.
    unawaited(_refreshUnreadCount());
  }

  void _onHomeProviderChanged() {
    final provider = _homeProvider;
    if (provider == null) return;
    if (provider.reloadVersion > _lastSeenReloadVersion) {
      _lastSeenReloadVersion = provider.reloadVersion;
      if (mounted) loadData();
    }
  }

  String _holdingsRefreshErrorMessage(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] is String) return d['message'] as String;
      return e.message ?? 'Could not refresh holdings';
    }
    if (e is StateError) {
      return e.message;
    }
    return 'Could not refresh holdings';
  }

  Future<void> _refreshHoldingsFromHome() async {
    if (_refreshingHoldings || !mounted) return;
    setState(() => _refreshingHoldings = true);
    try {
      await HoldingService.refreshPrimarySmallcaseHolding();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holdings refreshed')),
      );
      await loadData();
    } on StateError {
      if (!mounted) return;
      await context.pushNamed(RouteNames.MY_HOLDING_VIEW_SCREEN);
      if (!mounted) return;
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_holdingsRefreshErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _refreshingHoldings = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _homeProvider = context.read<HomeDataProvider>();
    _lastSeenReloadVersion = _homeProvider!.reloadVersion;
    _homeProvider!.addListener(_onHomeProviderChanged);
    loadData();
    unawaited(_refreshUnreadCount());
  }

  @override
  void dispose() {
    _homeProvider?.removeListener(_onHomeProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: SvgPicture.asset(
          Assets.ASSETS_LOGO_SVG,
          height: 22,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: _unreadCount > 0
                ? Badge(
                    label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      HugeIconsSolid.notification01,
                      color: AppColors.brand,
                    ),
                  )
                : Icon(
                    HugeIconsSolid.notification01,
                    color: AppColors.brand,
                  ),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return HomePageLoader();
          }
          if (_isError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load home data',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 16,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([loadData(), _refreshUnreadCount()]);
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      BorderCard(
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        borderWidth: 1,
                        color: SharePerksColors.primary.withValues(alpha: 0.3),
                        borderRadius: SharePerksRadii.lg,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: SharePerksColors.textPrimaryLight,
                                    fontSize: 16,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  context
                                          .watch<UserProvider>()
                                          .user
                                          ?.name
                                          ?.split(" ")[0] ??
                                      '',
                                  style: TextStyle(
                                    color: const Color(0xFF6400E0),
                                    fontSize: 16,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            if (data?.data?.unlockedRewards?.isBrokeConnected ==
                                false)
                              Image.asset(
                                Assets.ASSETS_CARDS_LINK_LIGHT_PNG,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            if (data?.data?.unlockedRewards?.isBrokeConnected ==
                                true)
                              RewardCountCard(
                                activePerks:
                                    (data?.data?.unlockedRewards?.total ?? "0")
                                        .toString(),
                                newRewards: "0",
                              ),
                          ],
                        ),
                      ),
                      if (data?.data?.slides?.isNotEmpty ?? false)
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200.0,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: Duration(
                              milliseconds: 800,
                            ),
                            autoPlayCurve: Curves.easeInOut,
                            aspectRatio: 16 / 9,
                            viewportFraction: 1.0,
                          ),
                          items: List.generate(
                            data?.data?.slides?.length ?? 0,
                            (index) {
                              String url =
                                  data?.data?.slides?[index].image ?? "";
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    SharePerksRadii.lg,
                                  ),
                                  child: Container(
                                    color: Colors.white,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return ImageBuilder(
                                          imageUrl: imageUrl(url),
                                          fit: BoxFit.cover,
                                          width: constraints.maxWidth,
                                          height: 100,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: SharePerksSpacing.sm),
                    ],
                  ),
                  if (data?.data?.unlockedRewards?.isImportInProgress ?? false)
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ImportProgressSection(),
                    ),
                  SizedBox(height: SharePerksSpacing.md),
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
                              'Top Perks',
                              style: TextStyle(
                                color: SharePerksColors.accent,
                                fontSize: 18,
                                fontFamily: SharePerksFonts.albertSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                context.pushNamed(RouteNames.TOP_PERKS_SCREEN);
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
                                  data?.data?.topRewards?.length ?? 0,
                                  (index) {
                                    RewardItem reward =
                                        data!.data!.topRewards![index];
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
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TitleView(
                          title: Text(
                            'Top Brands',
                            style: TextStyle(
                              color: const Color(0xFF333333),
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
                              iconSize: 18,
                              label: Text(
                                'View all',
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 13,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
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
                                data?.data?.topBrands?.length ?? 0,
                                (index) {
                                  BrandItem brand =
                                      data!.data!.topBrands![index];
                                  return BrandCard(
                                    onTap: () {
                                      context.pushNamed(
                                        RouteNames.BRAND_SCREEN,
                                        extra: {"brandId": brand.brandId},
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
                  SizedBox(height: 30),
                  if ((data?.data?.unlockedRewards?.rewards?.length ?? 0) != 0)
                    BorderCard(
                      width: double.infinity,
                      borderWidth: 1,
                      color: SharePerksColors.primary.withValues(alpha: 0.3),
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
                                'Unlocked Perks',
                                style: TextStyle(
                                  color: SharePerksColors.primary,
                                  fontSize: 18,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    RouteNames.UNLOCKED_PERKS_SCREEN,
                                  );
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
                                    data
                                            ?.data
                                            ?.unlockedRewards
                                            ?.rewards
                                            ?.length ??
                                        0,
                                    (index) {
                                      RewardItem reward = data!
                                          .data!
                                          .unlockedRewards!
                                          .rewards![index];
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
                  SizedBox(height: 26),

                  Image.asset(Assets.ASSETS_CARDS_DATA_SAFETY_PNG),
                  SizedBox(height: 30),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: TitleView(
                          title: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Explore',
                                  style: TextStyle(
                                    color: const Color(0xFF333333),
                                    fontSize: 18,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Catagories',
                                  style: TextStyle(
                                    color: SharePerksColors.primary,
                                    fontSize: 18,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              context.pushNamed(RouteNames.CATEGORY_SCREEN);
                            },
                            child: LabelWithForwardIcon(
                              iconSize: 18,
                              iconColor: SharePerksColors.textSecondaryLight,
                              label: Text(
                                'View all',
                                style: TextStyle(
                                  color: SharePerksColors.textSecondaryLight,
                                  fontSize: 13,
                                  fontFamily: SharePerksFonts.albertSans,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 6),
                            ...List.generate(
                              data?.data?.categories?.length ?? 0,
                              (index) {
                                HomeCategory category =
                                    data!.data!.categories![index];
                                return GestureDetector(
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.CATEGORY_SCREEN,
                                      extra: {"categoryId": category.id},
                                    );
                                  },
                                  child: CategoryView(
                                    image: imageUrl(category.image ?? ""),
                                    title: category.name ?? "--",
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 6),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      if (data?.data?.unlockedRewards?.remainderReimport ??
                          false)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _refreshingHoldings
                                  ? null
                                  : _refreshHoldingsFromHome,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    Assets.ASSETS_CARDS_REMINDER_PNG,
                                    width: MediaQuery.of(context).size.width,
                                  ),
                                  if (_refreshingHoldings)
                                    const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                          ],
                        ),

                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: TitleView(
                              title: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Explore',
                                      style: TextStyle(
                                        color: const Color(0xFF333333),
                                        fontSize: 18,
                                        fontFamily: SharePerksFonts.albertSans,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: SharePerksFonts.albertSans,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Types of Perks',
                                      style: TextStyle(
                                        color: SharePerksColors.primary,
                                        fontSize: 18,
                                        fontFamily: SharePerksFonts.albertSans,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: SizedBox(),
                            ),
                          ),
                          SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              spacing: 20,
                              children: [
                                OptionView(
                                  onTap: () => context.pushNamed(
                                    RouteNames.GIFTCARD_PERK_SCREEN,
                                  ),
                                  image: Assets.ASSETS_ICONS_GIFTCARD_PNG,
                                  title: "Credits",
                                ),
                                OptionView(
                                  onTap: () => context.pushNamed(
                                    RouteNames.PROMOOCODE_PERK_SCREEN,
                                  ),
                                  image: Assets.ASSETS_ICONS_DISCOUNT_PNG,
                                  title: "Discount\nCoupons",
                                ),
                                OptionView(
                                  onTap: () => context.pushNamed(
                                    RouteNames.CASHBACK_PERK_SCREEN,
                                  ),
                                  image: Assets.ASSETS_ICONS_CASHBACK_PNG,
                                  title: "Benefits",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      VotingBrands(),
                      Copyright(),
                      SizedBox(height: 80),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBarComponent(),
    );
  }
}
