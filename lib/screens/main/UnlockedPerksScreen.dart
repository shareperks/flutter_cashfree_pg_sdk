import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/components/loader/rewardloader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/unlocked_perks_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

enum UnlockedTierFilter { all, shareholder, member }

class UnlockedPerksScreen extends StatefulWidget {
  const UnlockedPerksScreen({
    super.key,
    this.initialTier = UnlockedTierFilter.all,
  });

  final UnlockedTierFilter initialTier;

  @override
  State<UnlockedPerksScreen> createState() => _UnlockedPerksScreenState();
}

class _UnlockedPerksScreenState extends State<UnlockedPerksScreen> {
  bool _loading = true;
  bool _isError = true;
  int _index = 0;
  late UnlockedTierFilter _tierFilter;

  UnlockedPerksResponse? perks;

  List<List<RewardItem>> rewardItems = [[], [], []];

  final TextEditingController _searchController = TextEditingController();
  Timer? _filterTimer;
  String _sortBy = 'a-z';

  List<RewardItem> get _filteredItems {
    final items = rewardItems[_index];
    switch (_tierFilter) {
      case UnlockedTierFilter.all:
        return items;
      case UnlockedTierFilter.shareholder:
        return items.where((r) => r.isEligible == true).toList();
      case UnlockedTierFilter.member:
        return items
            .where((r) => r.isEligible != true && r.isBrokerageEligible == true)
            .toList();
    }
  }

  bool isEmpty() => _filteredItems.isEmpty;

  Future<void> loadData() async {
    setState(() {
      _isError = false;
      _loading = true;
    });
    try {
      perks = await ListingDataService.getUnlockedPerks(
        search: _searchController.text.trim(),
        sort: _sortBy,
      );
      rewardItems[0] = perks?.data?.benefitRewardsEligibly ?? [];
      rewardItems[1] = perks?.data?.creditRewardsEligibly ?? [];
      rewardItems[2] = perks?.data?.offerRewardsEligibly ?? [];
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

  Future<void> applyFilter() async {
    _filterTimer?.cancel();
    _filterTimer = Timer(const Duration(milliseconds: 500), () async {
      await loadData();
    });
  }

  @override
  void initState() {
    super.initState();
    _tierFilter = widget.initialTier;
    loadData();
  }

  @override
  void dispose() {
    _filterTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: Text("Unlocked Perks"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return await applyFilter();
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategorySearchSortBar(
                  controller: _searchController,
                  sortBy: _sortBy,
                  onSearchChanged: (_) => applyFilter(),
                  onToggleSort: () {
                    setState(() {
                      _sortBy = _sortBy == 'a-z' ? 'z-a' : 'a-z';
                    });
                    applyFilter();
                  },
                ),
                SizedBox(height: 10),
                TabButtons(
                  selectedIndex: _index,
                  onTap: (index) {
                    setState(() {
                      _index = index;
                    });
                  },
                  layoutWidthInset: 44,
                  items: ["CashBack", "GiftCard", "Discount Code"],
                ),
                SizedBox(height: 12),
                if (!_loading && !_isError)
                  _UnlockedTierTabs(
                    selected: _tierFilter,
                    allCount: rewardItems[_index].length,
                    shareholderCount: rewardItems[_index]
                        .where((r) => r.isEligible == true)
                        .length,
                    memberCount: rewardItems[_index]
                        .where(
                          (r) =>
                              r.isEligible != true &&
                              r.isBrokerageEligible == true,
                        )
                        .length,
                    onChanged: (tier) => setState(() => _tierFilter = tier),
                  ),
                SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    if (_loading) {
                      return RewardLoader(
                        width: (MediaQuery.of(context).size.width / 2) - 23,
                      );
                    }
                    if (_isError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Failed to load unlocked perks'),
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
                    if (isEmpty()) {
                      return NotFoundView(subtitle: "In this Type");
                    }
                    final items = _filteredItems;
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        runAlignment: WrapAlignment.start,
                        alignment: WrapAlignment.start,
                        children: List.generate(items.length, (index) {
                          RewardItem reward = items[index];
                          return RewardCard(
                            width: (MediaQuery.of(context).size.width / 2) - 23,
                            rewardId: reward.id!,
                            type: reward.type!,
                            typeName: reward.type!,
                            title: reward.title!,
                            imageUrl: imageUrl(reward.image ?? ""),
                            isEligible: reward.isEligible ?? false,
                            isBrokerageEligible:
                                reward.isBrokerageEligible ?? false,
                            isNew: reward.isNew ?? false,
                            eligibility: reward.companyName ?? "--",
                          );
                        }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockedTierTabs extends StatelessWidget {
  const _UnlockedTierTabs({
    required this.selected,
    required this.allCount,
    required this.shareholderCount,
    required this.memberCount,
    required this.onChanged,
  });

  final UnlockedTierFilter selected;
  final int allCount;
  final int shareholderCount;
  final int memberCount;
  final ValueChanged<UnlockedTierFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UnlockedTierTab(
              label: 'All',
              count: allCount,
              selected: selected == UnlockedTierFilter.all,
              accent: SharePerksColors.textPrimaryLight,
              onTap: () => onChanged(UnlockedTierFilter.all),
            ),
          ),
          Expanded(
            child: _UnlockedTierTab(
              label: 'Shareholder',
              count: shareholderCount,
              selected: selected == UnlockedTierFilter.shareholder,
              accent: SharePerksColors.accent,
              onTap: () => onChanged(UnlockedTierFilter.shareholder),
            ),
          ),
          Expanded(
            child: _UnlockedTierTab(
              label: 'Brokerage',
              count: memberCount,
              selected: selected == UnlockedTierFilter.member,
              accent: SharePerksColors.primary,
              onTap: () => onChanged(UnlockedTierFilter.member),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedTierTab extends StatelessWidget {
  const _UnlockedTierTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accent : SharePerksColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? SharePerksColors.backgroundLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: fg.withValues(alpha: selected ? 1 : 0.75),
                fontSize: 10,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
