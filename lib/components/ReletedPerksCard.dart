import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/home_common_models.dart';
import 'package:shareperks/repository/services/listing/data.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/title_view.dart';

/// Similar perks on a perk detail page.
///
/// - Prefer API `relatedPerks`; fall back to same-category perks.
/// - Title is always "Similar Perks".
/// - View all and perk cards open [CategoryScreen] with [categoryId] selected.
class PerkRelatedSection extends StatefulWidget {
  const PerkRelatedSection({
    super.key,
    required this.relatedPerks,
    required this.categoryId,
    this.currentRewardId,
  });

  final List<RewardItem> relatedPerks;
  final String? categoryId;
  final String? currentRewardId;

  @override
  State<PerkRelatedSection> createState() => _PerkRelatedSectionState();
}

class _PerkRelatedSectionState extends State<PerkRelatedSection> {
  List<RewardItem> _categoryPerks = const [];
  bool _loadingCategory = false;

  String get _sectionTitle => 'Similar Perks';

  List<RewardItem> get _relatedPerks => widget.relatedPerks
      .where((r) => r.id != null && r.id != widget.currentRewardId)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadCategoryPerks();
  }

  @override
  void didUpdateWidget(covariant PerkRelatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.currentRewardId != widget.currentRewardId ||
        oldWidget.relatedPerks.length != widget.relatedPerks.length) {
      _loadCategoryPerks();
    }
  }

  Future<void> _loadCategoryPerks() async {
    // Only needed as fallback when company-related perks are missing.
    if (_relatedPerks.isNotEmpty) {
      if (mounted) {
        setState(() {
          _categoryPerks = const [];
          _loadingCategory = false;
        });
      }
      return;
    }

    final categoryId = widget.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      if (mounted) setState(() => _categoryPerks = const []);
      return;
    }

    setState(() => _loadingCategory = true);
    try {
      final response = await ListingDataService.getCategoryRewardList(
        categoryId: categoryId,
      );
      final currentId = widget.currentRewardId;
      final items = (response.data ?? [])
          .where((r) => r.id != null && r.id != currentId)
          .take(12)
          .toList();
      if (!mounted) return;
      setState(() => _categoryPerks = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoryPerks = const []);
    } finally {
      if (mounted) setState(() => _loadingCategory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final related = _relatedPerks;
    final hasRelated = related.isNotEmpty;
    final hasSimilar = _categoryPerks.isNotEmpty;

    // Prefer company-related perks. Fall back to similar (category) perks.
    // Keep the same title either way so it doesn't flicker/change.
    if (hasRelated) {
      return RelatedPerksCard(
        items: related,
        title: _sectionTitle,
        categoryId: widget.categoryId,
      );
    }

    if (hasSimilar) {
      return RelatedPerksCard(
        items: _categoryPerks,
        title: _sectionTitle,
        categoryId: widget.categoryId,
      );
    }

    if (_loadingCategory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class RelatedPerksCard extends StatelessWidget {
  final String title;
  final List<RewardItem> items;
  final String? categoryId;

  const RelatedPerksCard({
    super.key,
    required this.items,
    required this.title,
    this.categoryId,
  });

  void _openCategory(BuildContext context) {
    final id = categoryId;
    if (id == null || id.isEmpty) {
      context.pushNamed(RouteNames.CATEGORY_SCREEN);
      return;
    }
    context.pushNamed(RouteNames.CATEGORY_SCREEN, extra: {'categoryId': id});
  }

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      width: double.infinity,
      borderWidth: 1,
      color: SharePerksColors.accent.withValues(alpha: 0.3),
      borderRadius: SharePerksRadii.lg,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 10),
            child: TitleView(
              title: SizedBox(
                width: MediaQuery.of(context).size.width / 1.8,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SharePerksColors.accent,
                    fontSize: 18,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: GestureDetector(
                onTap: () => _openCategory(context),
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
                  ...List.generate(items.length, (index) {
                    RewardItem reward = items[index];
                    return RewardCard(
                      rewardId: reward.id!,
                      type: reward.type!,
                      typeName: reward.type,
                      title: reward.title ?? "--",
                      imageUrl: imageUrl(reward.image ?? ""),
                      isEligible: reward.isEligible ?? false,
                      isBrokerageEligible: reward.isBrokerageEligible ?? false,
                      eligibility: reward.companyName ?? "--",
                      source: 'similar_perks',
                      position: index,
                    );
                  }),
                  SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
