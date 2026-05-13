import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClaimedCard.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/loader/ClaimedPerksShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/models/my_claimed_rewards_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/rewards/PromoCodeRewardScreen.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';

class ClaimedPerksScreen extends StatefulWidget {
  const ClaimedPerksScreen({super.key});

  @override
  State<ClaimedPerksScreen> createState() => _ClaimedPerksScreenState();
}

enum _UsageTab { all, unused, used }

class _ClaimedPerksScreenState extends State<ClaimedPerksScreen> {
  MyClaimedRewardsResponse? data;
  bool _loading = true;
  bool _isError = false;
  final TextEditingController _searchController = TextEditingController();
  _UsageTab _usageTab = _UsageTab.all;

  /// Applies usage tab, then search on [rawQuery] (pass from [TextEditingController.text]).
  List<MyClaimedPerk> _visiblePerksForQuery(String rawQuery) {
    var list = List<MyClaimedPerk>.from(data?.data?.perks ?? <MyClaimedPerk>[]);
    switch (_usageTab) {
      case _UsageTab.unused:
        list = list.where((p) => p.used != true).toList();
        break;
      case _UsageTab.used:
        list = list.where((p) => p.used == true).toList();
        break;
      case _UsageTab.all:
        break;
    }
    final tokens = rawQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return list;

    return list.where((p) {
      final hay = [
        p.name,
        p.term,
        p.type,
        p.expireAtFormatted,
        p.expiredAt,
        p.rewardValue?.toString(),
        p.claimedId,
        p.rewardId,
        if (p.expired != null) '${p.expired}',
      ].whereType<String>().map((s) => s.toLowerCase()).join(' ');
      return tokens.every((t) => hay.contains(t));
    }).toList();
  }

  Future<void> loadData() async {
    try {
      data = await RewardListingDataService.getMyClaimedRewards();
    } catch (e) {
      _isError = true;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width / 2) - 23;

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
        title: Text("Claimed Perks"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
        },
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width,
            child: _loading
                ? const ClaimedPerksShimmer()
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BorderCard(
                            width: (MediaQuery.of(context).size.width / 2) - 20,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            borderWidth: 1,
                            borderRadius: 18,
                            color: AppColors.brand,
                            child: Column(
                              spacing: 6,
                              children: [
                                Text(
                                  'Total Value Saved',
                                  style: TextStyle(
                                    color: const Color(0xFF6400E0),
                                    fontSize: 12,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '₹ ${data?.data?.totalSaved ?? 0}',
                                  style: TextStyle(
                                    color: const Color(0xFF333333),
                                    fontSize: 22,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₹${data?.data?.savedThisMonth}+ this month',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 9.60,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w500,
                                    height: 1.38,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          BorderCard(
                            width: width,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            borderWidth: 1,
                            borderRadius: 18,
                            color: AppColors.brand,
                            child: Column(
                              spacing: 6,
                              children: [
                                Text(
                                  'Total Perks Claimed',
                                  style: TextStyle(
                                    color: const Color(0xFF6400E0),
                                    fontSize: 12,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '${data?.data?.totalUnlocked}',
                                  style: TextStyle(
                                    color: const Color(0xFF333333),
                                    fontSize: 22,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${data?.data?.thisMonthUnlocked} this month',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 9.60,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w500,
                                    height: 1.38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (data?.data?.isConnected?.connected ?? false)
                        Column(
                          children: [
                            Image.asset(
                              Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
                              width: MediaQuery.of(context).size.width,
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, searchValue, _) {
                          final q = searchValue.text.trim();
                          final list = _visiblePerksForQuery(searchValue.text);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(HugeIconsStroke.search01),
                                  hint: Text("Search Perk"),
                                  suffixIcon: q.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear',
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _searchController.clear(),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: SegmentedButton<_UsageTab>(
                                  segments: const [
                                    ButtonSegment(
                                      value: _UsageTab.all,
                                      label: Text('All'),
                                    ),
                                    ButtonSegment(
                                      value: _UsageTab.unused,
                                      label: Text('Unused'),
                                    ),
                                    ButtonSegment(
                                      value: _UsageTab.used,
                                      label: Text('Used'),
                                    ),
                                  ],
                                  selected: {_usageTab},
                                  onSelectionChanged: (Set<_UsageTab> next) {
                                    setState(() => _usageTab = next.first);
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (list.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Text(
                                    q.isNotEmpty
                                        ? 'No perks match your search.'
                                        : _usageTab == _UsageTab.unused
                                        ? 'No unused perks in this list.'
                                        : _usageTab == _UsageTab.used
                                        ? 'No used perks in this list.'
                                        : 'No claimed perks yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF898989),
                                      fontSize: 14,
                                      fontFamily: SharePerksFonts.albertSans,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: List.generate(list.length, (index) {
                                    final card = list[index];
                                    return Opacity(
                                      opacity: (card.used ?? false) ? 0.6 : 1,
                                      child: ClaimedCard(
                                        onTap: () {
                                          if (card.type == "CREDIT") {
                                            context.pushNamed(
                                              RouteNames
                                                  .CLAIMED_GIFTCARD_SCREEN,
                                              extra: {
                                                "claimedId": card.claimedId,
                                              },
                                            );
                                          }
                                          if (card.type == 'OFFER') {
                                            if (card.isExpired) {
                                              showClaimedPromoCodeSheet(
                                                context,
                                                data: PromocodeChimed(
                                                  chimedAt: card.expiredAt,
                                                  claimed: card.used,
                                                  code: card.code,
                                                  claimedId: card.claimedId,
                                                ),
                                                onUpdateRedeemed: () {
                                                  loadData();
                                                },
                                                name: card.name,
                                                rewardId: card.rewardId,
                                                subtitle: card.term,
                                              );
                                            } else {
                                              context.pushNamed(
                                                RouteNames
                                                    .PROMOCODE_VIEW_SCREEN,
                                                extra: {
                                                  "rewardId": card.rewardId,
                                                },
                                              );
                                            }
                                          }
                                        },
                                        width: width,
                                        imageUrl: imageUrl(card.image ?? ""),
                                        title: card.name ?? "",
                                        expiryLine:
                                            card.expireAtFormatted ??
                                            "No expiry",
                                        valueLine: card.term ?? "",
                                        expired: card.isExpired,
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 40),
                      ClickToHelp(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
