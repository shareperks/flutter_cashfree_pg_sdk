import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/holding/InvestmentAmountCard.dart';
import 'package:shareperks/components/holding/NoBrokerConnected.dart';
import 'package:shareperks/components/loader/HoldingsPageShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/biometric/biometric_gate.dart';
import 'package:shareperks/repository/providers/home-data.provider.dart';
import 'package:shareperks/repository/services/holding/holding.service.dart';
import 'package:shareperks/repository/services/holding/holding_builder.dart';
import 'package:shareperks/repository/services/holding/holding_model.dart';
import 'package:shareperks/utils/currency_format.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/theme.dart';

class MyHoldingScreen extends StatefulWidget {
  const MyHoldingScreen({super.key});

  @override
  State<MyHoldingScreen> createState() => _MyHoldingScreenState();
}

class _MyHoldingScreenState extends State<MyHoldingScreen> {
  bool _loading = true;
  bool _error = false;
  List<FetchUserHoldingsResponse> data = [];
  FetchUserHoldingsResponse? selectedHolding;

  List<HoldingSelectItem> selectItems = [];
  String? _selectedAccountId;
  bool _refreshingSmallcase = false;
  bool _settingPrimary = false;
  bool _biometricUnlocked = false;
  bool _holdingsRequested = false;

  Future<void> loadMyHoldings({bool? resync}) async {
    try {
      _error = false;
      data = await HoldingService.getHoldings();
      if (await HoldingService.ensurePrimaryHoldingIfNeeded(data)) {
        if (mounted) {
          context.read<HomeDataProvider>().requestReload();
        }
        data = await HoldingService.getHoldings();
      }
      selectItems = HoldingSelectBuilder.build(data);
      if (resync != false) {
        _syncDefaultAccount();
      }
    } catch (e) {
      _error = true;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _onBiometricUnlocked() {
    if (!_biometricUnlocked) {
      setState(() => _biometricUnlocked = true);
    }
    if (_holdingsRequested) return;
    _holdingsRequested = true;
    loadMyHoldings();
  }

  void _onBiometricLocked() {
    if (_biometricUnlocked) {
      setState(() => _biometricUnlocked = false);
    }
  }

  void _syncDefaultAccount() {
    if (selectItems.isEmpty) {
      _selectedAccountId = null;
      selectedHolding = null;
      return;
    }
    for (final item in selectItems) {
      if (item.holding.primary) {
        _selectedAccountId = item.id;
        selectedHolding = item.holding;
        return;
      }
    }
    _selectedAccountId = selectItems.first.id;
    selectedHolding = selectItems.first.holding;
  }

  HoldingSelectItem? _selectedAccount() {
    final id = _selectedAccountId;
    if (id == null) return null;
    for (final s in selectItems) {
      if (s.id == id) return s;
    }
    return null;
  }

  String _discardErrorMessage(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] is String) return d['message'] as String;
      return e.message ?? 'Could not disconnect broker';
    }
    return 'Could not disconnect broker';
  }

  Future<void> _onDisconnectBroker() async {
    final account = _selectedAccount();
    if (account == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect broker'),
        content: Text('Remove ${account.label} from your linked accounts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEB3939),
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await HoldingService.discardHolding(account.id);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (res.result) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
        setState(() => _loading = true);
        await loadMyHoldings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message.isNotEmpty ? res.message : 'Request failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_discardErrorMessage(e))));
    }
  }

  Future<void> _onMakePrimary(String holdingSnapshotId) async {
    if (_settingPrimary || !mounted) return;
    setState(() => _settingPrimary = true);
    try {
      final res = await HoldingService.markHoldingAsPrimary(holdingSnapshotId);
      if (!mounted) return;
      if (res.result) {
        // Eligibility on the home feed depends on which holding is primary,
        // so flag HomeScreen for a refresh on the user's next visit.
        context.read<HomeDataProvider>().requestReload();
        await loadMyHoldings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is now your primary')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update primary account')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiErrorMessage(e, 'Could not update primary')),
        ),
      );
    } finally {
      if (mounted) setState(() => _settingPrimary = false);
    }
  }

  FetchUserHoldingsResponse? _selectedHoldingSnapshot() {
    return _selectedAccount()?.holding ?? selectedHolding;
  }

  String _apiErrorMessage(Object e, String fallback) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['message'] is String) return d['message'] as String;
      return e.message ?? fallback;
    }
    return fallback;
  }

  Future<void> _onRefreshSmallcaseHolding() async {
    final h = _selectedHoldingSnapshot();
    if (h == null ||
        h.depository != 'SMALLCASE' ||
        _refreshingSmallcase ||
        !mounted) {
      return;
    }
    setState(() => _refreshingSmallcase = true);
    try {
      await HoldingService.refreshHoldingTransaction(h.id);
      if (!mounted) return;

      await loadMyHoldings(resync: false);
      if (!mounted) return;
      setState(() {
        _refreshingSmallcase = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Holdings refreshed')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _refreshingSmallcase = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiErrorMessage(e, 'Could not refresh holdings')),
        ),
      );
    }
  }

  Widget? _buildSmallcaseRefreshFab() {
    if (_loading || data.isEmpty) return null;
    final h = _selectedHoldingSnapshot();
    if (h == null || h.depository != 'SMALLCASE') return null;

    return FloatingActionButton(
      tooltip: 'Refresh holdings',
      onPressed: _refreshingSmallcase ? null : _onRefreshSmallcaseHolding,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(100),
      ),
      child: _refreshingSmallcase
          ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Icon(HugeIconsSolid.refreshDot),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text("My Holdings"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: BiometricGate(
        reason: 'Verify your identity to view your holdings',
        onUnlocked: _onBiometricUnlocked,
        onLocked: _onBiometricLocked,
        child: _buildHoldingsBody(),
      ),
      floatingActionButton: _biometricUnlocked
          ? _buildSmallcaseRefreshFab()
          : null,
    );
  }

  Widget _buildHoldingsBody() {
    return Builder(
      builder: (context) {
        if (_loading) {
          return const HoldingsPageShimmer();
        }
        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(28.0),
            child: NoBrokerConnected(),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await loadMyHoldings(resync: false);
          },
          child: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    () {
                      final h = _selectedAccount()?.holding ?? selectedHolding;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          if (h == null)
                            const InvestmentAmountCard(
                              amount: '₹ —',
                              snapshotDate: '—',
                              isPrimary: false,
                              isExpired: false,
                            )
                          else
                            InvestmentAmountCard(
                              amount: _formatPortfolioInr(h),
                              snapshotDate: _formatSnapshotDate(h.snapshotDate),
                              isPrimary: h.primary,
                              isExpired: h.reqReimport ?? false,
                            ),
                          if (h != null && !h.primary)
                            TextButton(
                              onPressed: _settingPrimary
                                  ? null
                                  : () => _onMakePrimary(h.id),

                              child: _settingPrimary
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SharePerksColors.primary,
                                    )
                                  : Text(
                                      'Make as primary',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                        ],
                      );
                    }(),

                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Row(
                            spacing: 10,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Color.fromARGB(255, 238, 238, 238),
                                    ),
                                  ),
                                  onPressed: () {
                                    context.pushNamed(
                                      RouteNames.LIST_BROKER_VIEW_SCREEN,
                                    );
                                  },
                                  child: Text(
                                    'Add broker',
                                    style: TextStyle(
                                      color: const Color(0xFF333333),
                                      fontSize: 14,
                                      fontFamily: SharePerksFonts.inter,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: PopupMenuButton<String>(
                                  tooltip: 'Switch broker account',
                                  offset: const Offset(0, 8),
                                  onSelected: (id) {
                                    setState(() {
                                      _selectedAccountId = id;
                                      selectedHolding = selectItems
                                          .firstWhere((e) => e.id == id)
                                          .holding;
                                    });
                                  },
                                  itemBuilder: (context) => [
                                    for (final item in selectItems)
                                      PopupMenuItem<String>(
                                        value: item.id,
                                        height: 35,
                                        child: Row(
                                          children: [
                                            item.leading,
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            if (item.holding.primary)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: Text(
                                                  'Primary',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          237,
                                          237,
                                          237,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedAccount()?.leading !=
                                            null) ...[
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              child:
                                                  _selectedAccount()!.leading,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Text(
                                            (_selectedAccount()?.label.split(
                                                  "(",
                                                )[0] ??
                                                'Accounts'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xFF333333),
                                              fontSize: 14,
                                              fontFamily: SharePerksFonts.inter,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Color(0xFF333333),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: InkWell(
                              onTap: _onDisconnectBroker,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      'Disconnect Broker',
                                      style: TextStyle(
                                        color: const Color(0xFFEB3939),
                                        fontSize: 14,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5.0),
                                      child: Icon(
                                        HugeIconsSolid.unlink02,
                                        size: 16,
                                        color: const Color(0xFFEB3939),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Your data remains secure. Shareperks operates ',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 10,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: 'strictly',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 10,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 10,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: 'post-investment',
                                  style: TextStyle(
                                    color: const Color(0xFF898989),
                                    fontSize: 10,
                                    fontFamily: SharePerksFonts.inter,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          BorderCard(
                            isGradientBackground: false,
                            color: SharePerksColors.primary.withAlpha(50),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            borderWidth: 1,
                            width: MediaQuery.of(context).size.width,
                            borderRadius: 14,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Holdings',
                                  style: TextStyle(
                                    color: SharePerksColors.primary,
                                    fontSize: 16,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    if (selectedHolding?.holdings.isEmpty ??
                                        false) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Text(
                                          'No Holdings Found',
                                          style: TextStyle(
                                            color: const Color(0xFF898989),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            height: 1.33,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        selectedHolding?.holdings.length ?? 0,
                                        (index) {
                                          int len =
                                              (selectedHolding
                                                      ?.holdings
                                                      .length ??
                                                  0) -
                                              1;
                                          UserHoldingLine? holding =
                                              selectedHolding?.holdings[index];
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: (len) == index
                                                  ? null
                                                  : Border(
                                                      bottom: BorderSide(
                                                        width: 1,
                                                        color: Color.fromARGB(
                                                          255,
                                                          239,
                                                          239,
                                                          239,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            child: ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.all(0),
                                              leading: ImageBuilder(
                                                imageUrl: holding?.logo ?? "",
                                                width: 40,
                                                height: 40,
                                                borderRadius: 100,
                                              ),
                                              title: Text(
                                                '${holding?.name}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF333333,
                                                  ),
                                                  fontSize: 12,
                                                  fontFamily:
                                                      SharePerksFonts.inter,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              subtitle: Text(
                                                holding?.isin ?? "",
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF898989,
                                                  ),
                                                  fontSize: 10,
                                                  fontFamily:
                                                      SharePerksFonts.inter,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                spacing: 4,
                                                children: [
                                                  Text(
                                                    'Qty ${holding?.quantity.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF333333,
                                                      ),
                                                      fontSize: 11,
                                                      fontFamily:
                                                          SharePerksFonts.inter,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${holding?.holdingDays} Days',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF898989,
                                                      ) /* Success */,
                                                      fontSize: 10,
                                                      fontFamily:
                                                          SharePerksFonts.inter,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        Assets.ASSETS_CARDS_LOYELSHAREHOLDER_PNG,
                      ),
                    ),
                    ClickToHelp(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatPortfolioInr(FetchUserHoldingsResponse h) {
  final total = h.holdings.fold<double>(0, (sum, line) => sum + line.value);
  return formatInrAmount(total, includeSymbol: true);
}

String _formatSnapshotDate(DateTime d) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = d.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
