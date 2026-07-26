import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/WalletCard.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/wallet_info_model.dart';
import 'package:shareperks/repository/services/wallet/wallet.service.dart';
import 'package:soui/elements/ShimmerBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  int _tabIndex = 0;
  String _searchQuery = '';
  List<WalletTransaction> _transactions = const [];
  bool _loading = true;
  bool _error = false;

  List<WalletTransaction> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _transactions;
    return _transactions.where((t) {
      final haystack = [
        t.displayTitle,
        t.reason,
        t.status,
        t.type,
        t.source,
        t.date,
        t.time,
        t.amount?.toString(),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _load() async {
    try {
      final List<WalletTransaction> rows;
      switch (_tabIndex) {
        case 1:
          // Full payout / withdrawal history.
          rows = await WalletDataService.getPayoutTransitions();
          break;
        case 2:
          // Full earnings / cashback history.
          rows = await WalletDataService.getCashbackTransitions();
          break;
        default:
          // All wallet movements.
          rows = await WalletDataService.getTransitions(
            tab: WalletTransitionsTab.all,
          );
          break;
      }
      if (!mounted) return;
      setState(() {
        _transactions = rows;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _transactions = const [];
        _error = true;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onTabTap(int index) {
    if (index == _tabIndex) return;
    setState(() {
      _tabIndex = index;
      _loading = true;
      _error = false;
    });
    _load();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = false;
    });
    _load();
  }

  static TransactionData _toCardData(WalletTransaction trx) {
    final title = trx.title?.trim();
    final label = (title != null && title.isNotEmpty)
        ? title
        : (trx.reason == 'PAYOUT' ? 'Withdrawal' : null);
    return TransactionData(
      amount: trx.amount ?? 0,
      date: trx.date ?? '',
      time: trx.time ?? '',
      type: trx.isDebit ? 'DEBIT' : 'CREDIT',
      label: label,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text('Wallet History'),
        toolbarHeight: 40,
        backgroundColor: SharePerksColors.borderDark,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loading = true;
            _error = false;
          });
          await _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 10,
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(HugeIconsSolid.search01),
                  hintText: 'Search',
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              TabButtons(
                selectedIndex: _tabIndex,
                onTap: _onTabTap,
                layoutWidthInset: 44,
                items: const ['All', 'Withdrawals', 'Earnings'],
              ),
              Expanded(child: _buildList(filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<WalletTransaction> filtered) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [_HistoryListShimmer()],
      );
    }
    if (_error) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _HistoryLoadError(onRetry: _retry),
          const Padding(
            padding: EdgeInsets.all(18),
            child: ClickToHelp(),
          ),
        ],
      );
    }
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
            child: Text(
              _searchQuery.trim().isEmpty
                  ? 'No transactions yet.'
                  : 'No transactions match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SharePerksFonts.albertSans,
                fontSize: 16,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: ClickToHelp(),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: ClickToHelp(),
          );
        }
        return TransactionCard(data: _toCardData(filtered[index]));
      },
    );
  }
}

class _HistoryListShimmer extends StatelessWidget {
  const _HistoryListShimmer();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 72;
    return Column(
      children: List.generate(
        6,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 5 ? 14 : 0),
          child: Row(
            children: [
              ShimmerBuilder(width: 28, height: 28, radius: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    ShimmerBuilder(width: w * 0.42, height: 16, radius: 6),
                    ShimmerBuilder(width: w * 0.55, height: 12, radius: 4),
                  ],
                ),
              ),
              ShimmerBuilder(width: 56, height: 14, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Column(
        children: [
          Text(
            'Could not load transaction history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SharePerksFonts.albertSans,
              fontSize: 16,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
