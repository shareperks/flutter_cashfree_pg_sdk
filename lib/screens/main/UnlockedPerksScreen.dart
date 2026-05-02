import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/components/loader/rewardloader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/unlocked_perks_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class UnlockedPerksScreen extends StatefulWidget {
  const UnlockedPerksScreen({super.key});

  @override
  State<UnlockedPerksScreen> createState() => _UnlockedPerksScreenState();
}

class _UnlockedPerksScreenState extends State<UnlockedPerksScreen> {
  bool _loading = true;
  bool _isError = true;
  int _index = 0;

  UnlockedPerksResponse? perks;

  List<List<RewardItem>> rewardItems = [[], [], []];

  final TextEditingController _searchController = TextEditingController();
  Timer? _filterTimer;
  String _sortBy = 'a-z';

  isEmpty() {
    return rewardItems[_index].isEmpty;
  }

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
    // TODO: implement initState
    super.initState();
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
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        runAlignment: WrapAlignment.start,
                        alignment: WrapAlignment.start,
                        children: List.generate(rewardItems[_index].length, (
                          index,
                        ) {
                          RewardItem reward = rewardItems[_index][index];
                          return RewardCard(
                            width: (MediaQuery.of(context).size.width / 2) - 23,
                            rewardId: reward.id!,
                            type: reward.type!,
                            typeName: reward.type!,
                            title: reward.title!,
                            imageUrl: imageUrl(reward.image ?? ""),
                            isEligible: reward.isEligible ?? false,

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
