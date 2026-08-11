import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/EmailCouponCard.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/email_coupon_model.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/gmail/gmail_coupon.service.dart';
import 'package:soui/elements/SpScafold.dart';

/// Lists coupons scraped from the user's connected Gmail inbox(es).
///
/// - Server-side search (`q`) with debounce
/// - Page-based infinite scroll
/// - App-bar action → Manage Google Accounts
class EmailCouponsScreen extends StatefulWidget {
  const EmailCouponsScreen({super.key});

  @override
  State<EmailCouponsScreen> createState() => _EmailCouponsScreenState();
}

class _EmailCouponsScreenState extends State<EmailCouponsScreen> {
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _isError = false;
  bool _gmailConnected = false;

  List<EmailCoupon> _items = <EmailCoupon>[];
  int _page = 1;
  bool _hasMore = false;
  String? _accountId;
  EmailCouponUsedFilter _usedFilter = EmailCouponUsedFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _accountId = GmailCouponService.resolveAccountId(
      fromUserProvider: context.read<UserProvider>().user?.id,
    );
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      unawaited(_loadMore());
    }
  }

  Future<void> _bootstrap() async {
    await Future.wait([_checkConnection(), _loadInitial()]);
  }

  Future<void> _checkConnection() async {
    final accountId = _accountId;
    if (accountId == null) {
      if (mounted) setState(() => _gmailConnected = false);
      return;
    }
    try {
      final status = await GmailCouponService.listAccounts(accountId);
      if (!mounted) return;
      setState(() => _gmailConnected = status.isConnected);
    } catch (_) {
      // Soft fail — connection badge is best-effort.
    }
  }

  Future<void> _loadInitial() async {
    final accountId = _accountId;
    if (accountId == null) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _isError = true;
        _items = const <EmailCoupon>[];
      });
      return;
    }

    setState(() {
      _initialLoading = true;
      _isError = false;
      _items = const <EmailCoupon>[];
      _page = 1;
      _hasMore = false;
    });

    try {
      final data = await GmailCouponService.listCoupons(
        accountId,
        page: 1,
        limit: _pageSize,
        q: _searchController.text,
        usedFilter: _usedFilter,
      );
      if (!mounted) return;
      setState(() {
        _items = data.coupons;
        _page = data.page;
        _hasMore = data.hasMore;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final accountId = _accountId;
    if (accountId == null) return;

    _refreshing = true;
    try {
      final results = await Future.wait([
        GmailCouponService.listCoupons(
          accountId,
          page: 1,
          limit: _pageSize,
          q: _searchController.text,
          usedFilter: _usedFilter,
        ),
        GmailCouponService.listAccounts(accountId),
      ]);
      if (!mounted) return;
      final data = results[0] as PaginatedEmailCouponsResponse;
      final status = results[1] as GmailAccountsByAccountIdResponse;
      setState(() {
        _items = data.coupons;
        _page = data.page;
        _hasMore = data.hasMore;
        _gmailConnected = status.isConnected;
        _isError = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_items.isEmpty) setState(() => _isError = true);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading || _refreshing || !_hasMore) return;
    final accountId = _accountId;
    if (accountId == null) return;

    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final data = await GmailCouponService.listCoupons(
        accountId,
        page: nextPage,
        limit: _pageSize,
        q: _searchController.text,
        usedFilter: _usedFilter,
      );
      if (!mounted) return;
      setState(() {
        _items = <EmailCoupon>[..._items, ...data.coupons];
        _page = data.page;
        _hasMore = data.hasMore;
      });
    } catch (_) {
      // Retry on next scroll trigger.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_loadInitial());
    });
  }

  void _onUsedFilterChanged(EmailCouponUsedFilter filter) {
    if (_usedFilter == filter) return;
    setState(() => _usedFilter = filter);
    unawaited(_loadInitial());
  }

  void _onCouponUsedChanged(EmailCoupon updated) {
    setState(() {
      final matchesFilter = switch (_usedFilter) {
        EmailCouponUsedFilter.all => true,
        EmailCouponUsedFilter.unused => !updated.used,
        EmailCouponUsedFilter.used => updated.used,
      };
      if (!matchesFilter) {
        _items = _items.where((c) => c.id != updated.id).toList();
      } else {
        _items = [
          for (final c in _items)
            if (c.id == updated.id) updated else c,
        ];
      }
    });
  }

  Future<void> _openManageAccounts() async {
    await context.pushNamed(RouteNames.MANAGE_GOOGLE_ACCOUNTS_SCREEN);
    if (!mounted) return;
    unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        toolbarHeight: 40,
        title: const Text('My Email Coupons'),
        actions: [
          IconButton(
            tooltip: 'Manage Google accounts',
            onPressed: _openManageAccounts,
            icon: Icon(
              HugeIconsStroke.mailSetting01,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(HugeIconsSolid.search01, size: 20),
                    hintText: 'Search brand, offer, or code',
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                for (final filter in EmailCouponUsedFilter.values) ...[
                  if (filter != EmailCouponUsedFilter.values.first)
                    const SizedBox(width: 6),
                  _UsedFilterChip(
                    label: filter.label,
                    selected: _usedFilter == filter,
                    onTap: () => _onUsedFilterChanged(filter),
                  ),
                ],
              ],
            ),
          ),
          if (!_gmailConnected && !_initialLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Material(
                color: SharePerksColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SharePerksRadii.lg),
                child: InkWell(
                  onTap: _openManageAccounts,
                  borderRadius: BorderRadius.circular(SharePerksRadii.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          HugeIconsSolid.mailAdd01,
                          size: 18,
                          color: SharePerksColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Connect Google to import coupons from your inbox',
                            style: TextStyle(
                              color: SharePerksColors.textPrimaryLight,
                              fontSize: 12,
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          HugeIconsStroke.arrowRight01,
                          size: 16,
                          color: SharePerksColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: List.generate(5, (_) => const _EmailCouponShimmer()),
      );
    }

    if (_isError && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              children: [
                Text(
                  'Could not load email coupons.',
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 13,
                    fontFamily: SharePerksFonts.inter,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadInitial,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      final searching = _searchController.text.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _EmptyCouponsState(
            searching: searching,
            gmailConnected: _gmailConnected,
            usedFilter: _usedFilter,
            onRefresh: _refresh,
            onManageAccounts: _openManageAccounts,
            onClearSearch: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            onShowAll: () => _onUsedFilterChanged(EmailCouponUsedFilter.all),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return EmailCouponCard(
          coupon: _items[index],
          onUsedChanged: _onCouponUsedChanged,
        );
      },
    );
  }
}

class _UsedFilterChip extends StatelessWidget {
  const _UsedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SharePerksRadii.md),
            color: selected
                ? SharePerksColors.primary
                : SharePerksColors.surfaceLight,
            border: Border.all(
              color: selected
                  ? SharePerksColors.primary
                  : SharePerksColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : SharePerksColors.textSecondaryLight,
                fontSize: 12,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCouponsState extends StatelessWidget {
  const _EmptyCouponsState({
    required this.searching,
    required this.gmailConnected,
    required this.usedFilter,
    required this.onRefresh,
    required this.onManageAccounts,
    required this.onClearSearch,
    required this.onShowAll,
  });

  final bool searching;
  final bool gmailConnected;
  final EmailCouponUsedFilter usedFilter;
  final Future<void> Function() onRefresh;
  final VoidCallback onManageAccounts;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return _EmptyCard(
        icon: HugeIconsSolid.search01,
        title: 'No matches found',
        body: 'Try a different brand, offer, or coupon code.',
        primaryLabel: 'Clear search',
        onPrimary: onClearSearch,
      );
    }

    if (usedFilter != EmailCouponUsedFilter.all) {
      return _EmptyCard(
        icon: usedFilter == EmailCouponUsedFilter.used
            ? HugeIconsSolid.tick02
            : HugeIconsSolid.couponPercent,
        title: usedFilter == EmailCouponUsedFilter.used
            ? 'No used coupons'
            : 'No unused coupons',
        body: usedFilter == EmailCouponUsedFilter.used
            ? 'Coupons you mark as used will show up here.'
            : 'You’re all caught up — switch to All to see every coupon.',
        primaryLabel: 'Show all',
        onPrimary: onShowAll,
      );
    }

    if (!gmailConnected) {
      return Column(
        children: [
          _EmptyCard(
            icon: HugeIconsSolid.mailAdd01,
            title: 'Connect Google to get started',
            body:
                'Link Gmail once and we’ll pull redeemable coupon codes from your offer emails.',
            primaryLabel: 'Connect Google',
            onPrimary: onManageAccounts,
          ),
          const SizedBox(height: 14),
          const _HowItWorksCard(
            steps: [
              (icon: HugeIconsSolid.mailAdd01, text: 'Connect your Gmail'),
              (
                icon: HugeIconsSolid.mailOpen01,
                text: 'We scan recent offer emails',
              ),
              (
                icon: HugeIconsSolid.couponPercent,
                text: 'Codes show up here, ready to copy',
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        _EmptyCard(
          icon: HugeIconsSolid.couponPercent,
          title: 'No coupons yet',
          body:
              'We’re checking your inbox for offer emails. The first scan can take a few minutes — pull to refresh anytime.',
          primaryLabel: 'Refresh',
          onPrimary: () => onRefresh(),
          secondaryLabel: 'Manage Google accounts',
          onSecondary: onManageAccounts,
        ),
        const SizedBox(height: 14),
        const _HowItWorksCard(
          steps: [
            (
              icon: HugeIconsSolid.mailOpen01,
              text: 'Scan last 7 days of offer mail',
            ),
            (
              icon: HugeIconsSolid.couponPercent,
              text: 'Extract redeemable codes',
            ),
            (
              icon: HugeIconsSolid.tick02,
              text: 'List them here by brand & offer',
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SharePerksColors.surfaceLight,
      borderRadius: BorderRadius.circular(SharePerksRadii.lg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: SharePerksColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 17,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SharePerksColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: TextStyle(
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(
                    color: SharePerksColors.primary,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.steps});

  final List<({IconData icon, String text})> steps;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SharePerksColors.surfaceLight,
      borderRadius: BorderRadius.circular(SharePerksRadii.lg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How it works',
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      steps[i].icon,
                      size: 14,
                      color: SharePerksColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        steps[i].text,
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailCouponShimmer extends StatelessWidget {
  const _EmailCouponShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 118,
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
      ),
    );
  }
}
