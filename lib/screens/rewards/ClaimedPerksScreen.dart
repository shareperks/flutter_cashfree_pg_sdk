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
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/cashback_detail_model.dart';
import 'package:shareperks/repository/models/my_claimed_rewards_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/rewards/PromoCodeRewardScreen.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';

class ClaimedPerksScreen extends StatefulWidget {
  const ClaimedPerksScreen({super.key});

  @override
  State<ClaimedPerksScreen> createState() => _ClaimedPerksScreenState();
}

enum _UsageTab { all, unused, used }

String _claimedTypeLabel(String? type) {
  switch ((type ?? '').toUpperCase()) {
    case 'CREDIT':
      return 'Gift Card';
    case 'OFFER':
      return 'Discount';
    case 'BENEFIT':
      return 'Cashback';
    default:
      return type?.trim().isNotEmpty == true ? type!.trim() : '';
  }
}

class _ClaimedPerksScreenState extends State<ClaimedPerksScreen> {
  MyClaimedRewardsResponse? data;
  bool _loading = true;
  bool _isError = false;
  final TextEditingController _searchController = TextEditingController();
  _UsageTab _usageTab = _UsageTab.all;

  List<MyClaimedPerk> get _allPerks =>
      data?.data?.perks ?? <MyClaimedPerk>[];

  int get _unusedCount => _allPerks.where((p) => p.used != true).length;

  int get _usedCount => _allPerks.where((p) => p.used == true).length;

  /// Applies usage tab, then search on [rawQuery].
  List<MyClaimedPerk> _visiblePerksForQuery(String rawQuery) {
    var list = List<MyClaimedPerk>.from(_allPerks);
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
      _isError = false;
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

  void _openPerk(MyClaimedPerk card) {
    if (card.type == 'CREDIT') {
      context.pushNamed(
        RouteNames.CLAIMED_GIFTCARD_SCREEN,
        extra: {'claimedId': card.claimedId},
      );
      return;
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
          onUpdateRedeemed: loadData,
          name: card.name,
          rewardId: card.rewardId,
          subtitle: card.term,
        );
      } else {
        context.pushNamed(
          RouteNames.PROMOCODE_VIEW_SCREEN,
          extra: {'rewardId': card.rewardId},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 16 * 2 - 14) / 2;

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
        title: const Text('Claimed Perks'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: _loading
              ? const ClaimedPerksShimmer()
              : _isError
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('Could not load claimed perks.')),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Value Saved',
                            value: '₹ ${data?.data?.totalSaved ?? 0}',
                            subtitle:
                                '₹${data?.data?.savedThisMonth ?? 0}+ this month',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Perks Claimed',
                            value: '${data?.data?.totalUnlocked ?? 0}',
                            subtitle:
                                '${data?.data?.thisMonthUnlocked ?? 0} this month',
                          ),
                        ),
                      ],
                    ),
                    if (data?.data?.isConnected?.connected ?? false) ...[
                      const SizedBox(height: 16),
                      Image.asset(
                        Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
                        width: screenW,
                      ),
                    ],
                    const SizedBox(height: 16),
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
                                prefixIcon: const Icon(
                                  HugeIconsSolid.search01,
                                  size: 20,
                                ),
                                hintText: 'Search claimed perks',
                                suffixIcon: q.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _UsageTabs(
                              selected: _usageTab,
                              allCount: _allPerks.length,
                              unusedCount: _unusedCount,
                              usedCount: _usedCount,
                              onChanged: (tab) {
                                setState(() => _usageTab = tab);
                              },
                            ),
                            const SizedBox(height: 16),
                            if (list.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                ),
                                child: Text(
                                  q.isNotEmpty
                                      ? 'No perks match your search.'
                                      : _usageTab == _UsageTab.unused
                                      ? 'No unused perks yet.'
                                      : _usageTab == _UsageTab.used
                                      ? 'No used perks yet.'
                                      : 'No claimed perks yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: SharePerksColors.textSecondaryLight,
                                    fontSize: 14,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: list.map((card) {
                                  final dimmed =
                                      (card.used ?? false) || card.isExpired;
                                  return Opacity(
                                    opacity: dimmed ? 0.72 : 1,
                                    child: ClaimedCard(
                                      onTap: () => _openPerk(card),
                                      width: cardW,
                                      imageUrl: imageUrl(card.image ?? ''),
                                      title: card.name ?? '',
                                      expiryLine:
                                          card.expireAtFormatted ?? 'No expiry',
                                      valueLine: card.term ?? '',
                                      expired: card.isExpired,
                                      used: card.used == true,
                                      typeLabel: _claimedTypeLabel(card.type),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const ClickToHelp(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BorderCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      borderWidth: 1,
      borderRadius: 16,
      color: SharePerksColors.primary,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SharePerksColors.primary,
              fontSize: 12,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SharePerksColors.textPrimaryLight,
              fontSize: 22,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SharePerksColors.textSecondaryLight,
              fontSize: 10,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageTabs extends StatelessWidget {
  const _UsageTabs({
    required this.selected,
    required this.allCount,
    required this.unusedCount,
    required this.usedCount,
    required this.onChanged,
  });

  final _UsageTab selected;
  final int allCount;
  final int unusedCount;
  final int usedCount;
  final ValueChanged<_UsageTab> onChanged;

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
            child: _UsageTabChip(
              label: 'All',
              count: allCount,
              selected: selected == _UsageTab.all,
              accent: SharePerksColors.textPrimaryLight,
              onTap: () => onChanged(_UsageTab.all),
            ),
          ),
          Expanded(
            child: _UsageTabChip(
              label: 'Unused',
              count: unusedCount,
              selected: selected == _UsageTab.unused,
              accent: SharePerksColors.primary,
              onTap: () => onChanged(_UsageTab.unused),
            ),
          ),
          Expanded(
            child: _UsageTabChip(
              label: 'Used',
              count: usedCount,
              selected: selected == _UsageTab.used,
              accent: SharePerksColors.textSecondaryLight,
              onTap: () => onChanged(_UsageTab.used),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageTabChip extends StatelessWidget {
  const _UsageTabChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  fontSize: 12,
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
                fontSize: 11,
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
