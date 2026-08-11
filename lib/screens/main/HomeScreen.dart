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
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/navigation/home_slide_navigation.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/holding/holding.service.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/repository/services/notification/notification.service.dart';
import 'package:shareperks/screens/refer/ReferAndEarnCodeScreen.dart';
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
    final sw = Stopwatch()..start();
    setState(() {
      _isError = false;
      _loading = true;
    });
    try {
      data = await ListingDataService.getHomeData();
      await trackAction(AnalyticsEvent.homeLoaded, {
        'latency_ms': sw.elapsedMilliseconds,
        'is_error': false,
      });
    } catch (e) {
      _isError = true;
      await trackAction(AnalyticsEvent.homeLoaded, {
        'latency_ms': sw.elapsedMilliseconds,
        'is_error': true,
      });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Holdings refreshed')));
      await loadData();
    } on StateError {
      if (!mounted) return;
      await context.pushNamed(RouteNames.MY_HOLDING_VIEW_SCREEN);
      if (!mounted) return;
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_holdingsRefreshErrorMessage(e))));
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

  Widget _homeSearchField(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.SEARCH_REWARDS_SCREEN),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SharePerksColors.borderLight, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              HugeIconsSolid.search01,
              size: 15,
              color: SharePerksColors.textSecondaryLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search brands & perks',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: SharePerksColors.textSecondaryLight,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeNotificationAction() {
    return IconButton(
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
          : Icon(HugeIconsSolid.notification01, color: AppColors.brand),
    );
  }

  Widget _homeSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      stretch: false,
      primary: true,
      toolbarHeight: 48,
      expandedHeight: 108,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: 0,
      title: SvgPicture.asset(
        Assets.ASSETS_LOGO_SVG,
        height: 20,
        fit: BoxFit.contain,
      ),
      actions: [_homeNotificationAction(), const SizedBox(width: 4)],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SharePerksColors.primary.withValues(alpha: 0.06),
                Colors.white,
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: _homeSearchField(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = HomeSlide.visibleSlides(data?.data?.slides);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          print(data?.data?.unlockedRewards?.toJson() ?? {});
          await Future.wait([loadData(), _refreshUnreadCount()]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _homeSliverAppBar(context),

            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: HomePageLoader(),
              )
            else if (_isError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                ),
              )
            else
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    BorderCard(
                      padding: EdgeInsets.all(16).copyWith(bottom: 0.0),
                      width: double.infinity,
                      borderWidth: 1,
                      color: SharePerksColors.primary.withValues(alpha: 0.3),
                      borderRadius: SharePerksRadii.lg,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 3,
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
                                context.watch<UserProvider>().user?.name?.split(
                                      " ",
                                    )[0] ??
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
                            GestureDetector(
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.LIST_BROKER_VIEW_SCREEN,
                                );
                              },
                              child: Image.asset(
                                Assets.ASSETS_CARDS_LINK_LIGHT_PNG,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),

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
                                        width: MediaQuery.of(
                                          context,
                                        ).size.width,
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
                              ],
                            ),

                          if (data?.data?.unlockedRewards?.isBrokeConnected ==
                                  true &&
                              !(data
                                      ?.data
                                      ?.unlockedRewards
                                      ?.remainderReimport ??
                                  false))
                            RewardCountCard(
                              activePerks:
                                  (data?.data?.unlockedRewards?.total ?? 0)
                                      .toString(),
                              newRewards:
                                  data?.data?.newRewards?.toString() ?? "0",
                              memberUnlocked:
                                  data
                                      ?.data
                                      ?.unlockedRewards
                                      ?.fullUnlockedCount ??
                                  0,
                            ),
                        ],
                      ),
                    ),
                    // const EmailCouponsHomeSection(),
                    if (slides.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 230.0,
                          autoPlay: true,
                          autoPlayInterval: Duration(seconds: 3),
                          autoPlayAnimationDuration: Duration(
                            milliseconds: 800,
                          ),
                          autoPlayCurve: Curves.easeInOut,
                          aspectRatio: 16 / 9,
                          viewportFraction: 1.0,
                        ),
                        items: List.generate(slides.length, (index) {
                          final slide = slides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ).copyWith(bottom: 10.0, top: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => navigateHomeSlide(
                                slide,
                                source: 'home_carousel',
                                position: index,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    SharePerksRadii.lg,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        93,
                                        86,
                                        92,
                                        100,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: Offset(0, 0),
                                    ),
                                  ],

                                  color: Colors.white,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return ImageBuilder(
                                      imageUrl: imageUrl(
                                        slide.displayImageSource,
                                      ),
                                      fit: BoxFit.cover,
                                      width: constraints.maxWidth,
                                      borderRadius: SharePerksRadii.lg,
                                      height: 100,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    if (data?.data?.unlockedRewards?.isImportInProgress ??
                        false)
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
                                  context.pushNamed(
                                    RouteNames.TOP_PERKS_SCREEN,
                                  );
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
                          SizedBox(height: 5),
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
                                        isBrokerageEligible:
                                            reward.isBrokerageEligible ?? false,
                                        eligibility: reward.companyName ?? "--",
                                        onTap: () => navigateRewardScreen(
                                          reward.type!,
                                          reward.id!,
                                          source: 'home_top_perks',
                                          position: index,
                                        ),
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
                    SizedBox(height: 30),
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
                        SizedBox(height: 14),
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
                    SizedBox(height: 20),
                    if ((data?.data?.unlockedRewards?.rewards?.length ?? 0) !=
                        0)
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
                                          imageUrl: imageUrl(
                                            reward.image ?? "",
                                          ),
                                          isEligible:
                                              reward.isEligible ?? false,
                                          isBrokerageEligible:
                                              reward.isBrokerageEligible ??
                                              false,
                                          eligibility:
                                              reward.companyName ?? "--",
                                          onTap: () => navigateRewardScreen(
                                            reward.type!,
                                            reward.id!,
                                            source: 'home_unlocked_perks',
                                            position: index,
                                          ),
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

                    GestureDetector(
                      onTap: () {
                        context.pushNamed(RouteNames.DATA_SECURITY_INFO_SCREEN);
                      },
                      child: Image.asset(Assets.ASSETS_CARDS_DATA_SAFETY_PNG),
                    ),
                    SizedBox(height: 20),
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
                                    text: 'Categories',
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
                        SizedBox(height: 50),

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
                                          fontFamily:
                                              SharePerksFonts.albertSans,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily:
                                              SharePerksFonts.albertSans,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Types of Perks',
                                        style: TextStyle(
                                          color: SharePerksColors.primary,
                                          fontSize: 18,
                                          fontFamily:
                                              SharePerksFonts.albertSans,
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
                                horizontal: 10.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 40,
                                children: [
                                  OptionView(
                                    onTap: () => context.pushNamed(
                                      RouteNames.GIFTCARD_PERK_SCREEN,
                                    ),
                                    image: Assets.ASSETS_ICONS_GIFTCARD_PNG,
                                    title: "Gift Cards",
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
                                    title: "Cashback",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        VotingBrands(),
                        SizedBox(height: 30),
                        SortRefer(),
                        Copyright(),
                        SizedBox(height: 110),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarComponent(),
    );
  }
}

class SortRefer extends StatelessWidget {
  const SortRefer({super.key});

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      width: MediaQuery.of(context).size.width,
      borderWidth: 1,
      borderRadius: 16,
      color: SharePerksColors.primary.withValues(alpha: 0.2),
      isGradientBackground: true,
      backgroundColor: SharePerksColors.primary.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(12.0).copyWith(bottom: 0.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  Assets.ASSETS_ICONS_HAND_PNG,
                  width: 64,
                  height: 64,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Refer & ',
                            style: TextStyle(
                              color: AppColors.brand,
                              fontSize: 20,
                              fontFamily: 'Albert Sans',
                              fontWeight: FontWeight.w600,
                              height: 1.21,
                            ),
                          ),
                          TextSpan(
                            text: 'Earn',
                            style: TextStyle(
                              color: const Color(0xFFFF4AA7),
                              fontSize: 20,
                              fontFamily: 'Albert Sans',
                              fontWeight: FontWeight.w600,
                              height: 1.21,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 110,
                      child: Text(
                        "Every time you invite your friends, you and your friend get ₹100 cash back from Shareperks. ",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w400,
                          color: SharePerksColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            CopyReferCode(),
            TextButton(
              onPressed: () {},
              child: Text(
                'Terms & Conditions apply.',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
