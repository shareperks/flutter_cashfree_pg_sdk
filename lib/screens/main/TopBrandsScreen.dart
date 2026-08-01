import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/BrandCard.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/loader/brand_page_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/models/brand_list_model.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/theme.dart';

class TopBrandsScreen extends StatefulWidget {
  const TopBrandsScreen({super.key});

  @override
  State<TopBrandsScreen> createState() => _TopBrandsScreenState();
}

class _TopBrandsScreenState extends State<TopBrandsScreen> {
  bool _loading = true;
  bool _isError = false;

  BrandListResponse? _response;
  List<BrandItem> _brands = [];

  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;
  String _sortBy = 'a-z';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _isError = false;
    });

    try {
      _response = await ListingDataService.getTopBrands(
        search: _searchController.text.trim(),
        sort: _sortBy,
      );
      _brands = _response?.data ?? [];
    } catch (_) {
      _isError = true;
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () async {
      await _load();
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width / 2) - 23;

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: const Text("Top Brands"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  spacing: 5,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(HugeIconsSolid.search01),
                          hintText: "Search Brands",
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sortBy = _sortBy == 'a-z' ? 'z-a' : 'a-z';
                        });
                        _applyFilter();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 44,
                        child: Center(
                          child: Icon(
                            _sortBy == 'a-z'
                                ? HugeIconsSolid.sortingAZ02
                                : HugeIconsSolid.sortingZA01,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    if (_loading) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: BrandPageLoader(width: width),
                      );
                    }

                    if (_isError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 160.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Failed to load brands'),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_brands.isEmpty) {
                      return const NotFoundView(subtitle: "No brands found");
                    }

                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_brands.length, (index) {
                          final brand = _brands[index];
                          return BrandCard(
                            width: width,
                            isNew: brand.isNew ?? false,
                            title: brand.name ?? "--",
                            imageUrl: imageUrl(brand.image ?? ""),
                            onTap: () {
                              context.pushNamed(
                                RouteNames.BRAND_SCREEN,
                                extra: {"brandId": brand.id},
                              );
                            },
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
