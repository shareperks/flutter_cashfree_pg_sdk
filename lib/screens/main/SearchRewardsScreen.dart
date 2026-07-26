import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/components/loader/rewardloader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/reward_list_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class SearchRewardsScreen extends StatefulWidget {
  const SearchRewardsScreen({super.key});

  @override
  State<SearchRewardsScreen> createState() => _SearchRewardsScreenState();
}

class _SearchRewardsScreenState extends State<SearchRewardsScreen> {
  bool _loading = true;
  bool _isError = false;
  int _index = 0;

  RewardListResponse? perks;
  List<RewardItem> rewardItems = [];

  /// Index 0 = All (omit type). Rest map to API type enums.
  final List<String?> tabOption = [null, 'BENEFIT', 'CREDIT', 'OFFER'];

  final TextEditingController _searchController = TextEditingController();
  Timer? _filterTimer;
  String _sortBy = 'a-z';

  bool isEmpty() => rewardItems.isEmpty;

  Future<void> loadData() async {
    setState(() {
      _isError = false;
      _loading = true;
    });
    try {
      final query = _searchController.text.trim();
      perks = await ListingDataService.searchRewards(
        search: query.isEmpty ? null : query,
        sort: _sortBy,
        type: tabOption[_index],
      );
      rewardItems = perks?.data ?? [];
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
        title: Text('Search'),
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
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(18),
            child: Column(
              children: [
                CategorySearchSortBar(
                  controller: _searchController,
                  sortBy: _sortBy,
                  autofocus: true,
                  hintText: 'Search brands & perks',
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
                    applyFilter();
                  },
                  layoutWidthInset: 44,
                  items: ['All', 'CashBack', 'GiftCard', 'Discount Code'],
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
                              const Text('Failed to load search results'),
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
                      return NotFoundView(subtitle: 'No matching perks');
                    }
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        runAlignment: WrapAlignment.start,
                        alignment: WrapAlignment.start,
                        children: List.generate(rewardItems.length, (index) {
                          RewardItem reward = rewardItems[index];
                          return RewardCard(
                            width: (MediaQuery.of(context).size.width / 2) - 23,
                            rewardId: reward.id!,
                            type: reward.type!,
                            typeName: reward.type!,
                            title: reward.title!,
                            imageUrl: imageUrl(reward.image ?? ''),
                            isEligible: reward.isEligible ?? false,
                            isBrokerageEligible: reward.isBrokerageEligible ?? false,
                            eligibility: reward.companyName ?? '--',
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
