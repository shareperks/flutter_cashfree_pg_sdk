import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/CategoryView.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/components/loader/category_page_loader.dart';
import 'package:shareperks/components/loader/rewardloader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';
import 'package:shareperks/repository/models/reward_list_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';

class CategoryScreen extends StatefulWidget {
  final String? categoryId;
  const CategoryScreen({super.key, this.categoryId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  CategoryListResponse? categoryList;
  RewardListResponse? rewardsList;
  bool isError = false;
  bool categoryLoading = true;
  bool dataLoading = false;

  String? selectedCategory;
  String sortBy = "a-z"; // z-a
  TextEditingController searchController = TextEditingController();

  Future<void> loadCategory() async {
    setState(() {
      isError = false;
      categoryLoading = true;
    });
    try {
      categoryList = await ListingDataService.getCategoryList();
      selectedCategory ??= categoryList?.data?.first.id;
      if (selectedCategory != null) {
        await loadRewards(selectedCategory!);
      }
    } catch (e) {
      isError = true;
    } finally {
      if (mounted) {
        setState(() => categoryLoading = false);
      }
    }
  }

  Future<void> loadRewards(String categoryId) async {
    setState(() {
      isError = false;
      dataLoading = true;
      selectedCategory = categoryId;
    });
    try {
      rewardsList = await ListingDataService.getCategoryRewardList(
        categoryId: categoryId,
        search: searchController.text,
        sort: sortBy,
      );
      selectedCategory ??= categoryList?.data?.first.id;
    } catch (e) {
      isError = true;
    } finally {
      if (mounted) {
        setState(() => dataLoading = false);
      }
    }
  }

  Timer? _timer;

  Future<void> applyFilter() async {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () async {
      final categoryId = selectedCategory;
      if (categoryId == null) return;
      await loadRewards(categoryId);
    });
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.categoryId;
    loadCategory();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        title: Text('Catagories'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
        centerTitle: false,
        leading: AppBackButton(),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          SizedBox(width: 20),
        ],
      ),

      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: RefreshIndicator(
          onRefresh: loadCategory,
          child: Builder(
            builder: (context) {
              if (categoryLoading) {
                return const CategoryPageLoader();
              }
              if (isError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Failed to load categories'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadCategory,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  spacing: 18.0,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                SizedBox(width: 6),
                                ...List.generate(
                                  categoryList?.data?.length ?? 0,
                                  (index) {
                                    CategoryModel category =
                                        categoryList!.data![index];
                                    return CategoryViewTab(
                                      title: category.name ?? "--",
                                      image: imageUrl(category.image ?? ""),
                                      isActive: selectedCategory == category.id,
                                      onTap: () async {
                                        await loadRewards(category.id!);
                                      },
                                    );
                                  },
                                ),
                                SizedBox(width: 6),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                            ),
                            child: CategorySearchSortBar(
                              controller: searchController,
                              sortBy: sortBy,
                              onSearchChanged: (_) => applyFilter(),
                              onToggleSort: () {
                                setState(() {
                                  sortBy = sortBy == "a-z" ? "z-a" : "a-z";
                                });
                                applyFilter();
                              },
                            ),
                          ),
                          SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                            ),
                            child: Builder(
                              builder: (context) {
                                if (dataLoading) {
                                  return RewardLoader(
                                    width:
                                        (MediaQuery.of(context).size.width /
                                            2) -
                                        23,
                                  );
                                }
                                if (rewardsList?.data != null &&
                                    rewardsList!.data!.isEmpty) {
                                  return NotFoundView();
                                }
                                return SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
                                    runAlignment: WrapAlignment.start,
                                    alignment: WrapAlignment.start,
                                    children: List.generate(
                                      rewardsList?.data?.length ?? 0,
                                      (index) {
                                        RewardItem reward =
                                            rewardsList!.data![index];
                                        return RewardCard(
                                          width:
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width /
                                                  2) -
                                              23,
                                          rewardId: reward.id!,
                                          type: reward.type!,
                                          typeName: reward.type!,
                                          title: reward.title!,
                                          imageUrl: imageUrl(
                                            reward.image ?? "",
                                          ),
                                          isEligible:
                                              reward.isEligible ?? false,
                                          isBrokerageEligible:
                                              reward.isBrokerageEligible ?? false,

                                          eligibility:
                                              reward.companyName ?? "--",
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
