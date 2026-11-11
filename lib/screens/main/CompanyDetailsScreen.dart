import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/company/nested_cash_flow_table.dart';
import 'package:shareperks/components/company/nested_financial_table.dart';
import 'package:shareperks/components/company/screener_analysis.dart';
import 'package:shareperks/components/company/screener_corporate_actions.dart';
import 'package:shareperks/components/company/screener_documents.dart';
import 'package:shareperks/components/company/screener_header.dart';
import 'package:shareperks/components/company/screener_overview_stats.dart';
import 'package:shareperks/components/company/screener_peers_table.dart';
import 'package:shareperks/components/company/screener_price_chart.dart';
import 'package:shareperks/components/company/screener_ratios_table.dart';
import 'package:shareperks/components/company/screener_segments.dart';
import 'package:shareperks/components/company/screener_shareholding.dart';
import 'package:shareperks/components/loader/company_details_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';
import 'package:shareperks/repository/services/company/company_data.service.dart';
import 'package:soui/elements/SpScafold.dart';

/// Screener-style company details, powered by the Finance API.
///
/// Five tabs — Overview, Financials, Holding, Peers, Filings — each rendering
/// the API's native nested structure. Data is fetched once via
/// [CompanyDataService.getScreenerPage] which returns [ScreenerCompanyPage].
class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key, required this.symbol});

  final String symbol;

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  _CompanyTab _tab = _CompanyTab.overview;
  Consolidation _consolidation = Consolidation.consolidated;

  bool _loading = true;
  CompanyApiException? _error;
  ScreenerCompanyPage? _page;

  /// Chart time frame state.
  String _chartRange = '1Yr';
  ScreenerChart? _filteredChart;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await CompanyDataService.getScreenerPage(
        widget.symbol,
        consolidation: _consolidation,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
      _updateChart(_chartRange);
    } on CompanyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = const CompanyApiException(
          status: 500,
          message: 'Something went wrong',
        );
        _loading = false;
      });
    }
  }

  void _updateChart(String range) {
    setState(() => _chartRange = range);
    final chart = _page?.data.chart;
    if (chart == null) {
      _filteredChart = null;
      return;
    }
    final days = _rangeDays(range);
    _filteredChart = chart.filtered(days);
    setState(() {});
  }

  int _rangeDays(String range) => switch (range) {
    '1M' => 30,
    '6M' => 180,
    '1Yr' => 365,
    '3Yr' => 1095,
    '5Yr' => 1825,
    '10Yr' => 3650,
    _ => 99999,
  };

  Future<void> _setConsolidation(Consolidation value) async {
    if (value == _consolidation) return;
    setState(() => _consolidation = value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final ready = !_loading && _error == null && page != null;

    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: const AppBackButton(),
        toolbarHeight: 40,
        title: Text(page?.data.profile.symbol ?? widget.symbol.toUpperCase()),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      bottomNavigationBar: ready ? _bottomBar() : null,
      body: Builder(
        builder: (context) {
          if (_loading) return const CompanyDetailsLoader();
          if (_error != null) return _errorView(_error!);
          if (page == null) {
            return _errorView(
              const CompanyApiException(status: 500, message: 'No data'),
            );
          }
          return _tabView(page);
        },
      ),
    );
  }

  Widget _bottomBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: SharePerksColors.backgroundLight,
        indicatorColor: SharePerksColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontFamily: SharePerksFonts.inter,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? SharePerksColors.primary
                : SharePerksColors.textSecondaryLight,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? SharePerksColors.primary
                : SharePerksColors.textSecondaryLight,
          ),
        ),
      ),
      child: NavigationBar(
        height: 64,
        elevation: 3,
        selectedIndex: _tab.index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) =>
            setState(() => _tab = _CompanyTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(HugeIconsStroke.analyticsUp),
            selectedIcon: Icon(HugeIconsSolid.analyticsUp),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(HugeIconsStroke.rupee),
            selectedIcon: Icon(HugeIconsSolid.rupee),
            label: 'Financials',
          ),
          NavigationDestination(
            icon: Icon(HugeIconsStroke.shieldUser),
            selectedIcon: Icon(HugeIconsSolid.shieldUser),
            label: 'Holding',
          ),
          NavigationDestination(
            icon: Icon(HugeIconsStroke.userGroup),
            selectedIcon: Icon(HugeIconsSolid.userGroup),
            label: 'Peers',
          ),
          NavigationDestination(
            icon: Icon(HugeIconsStroke.note01),
            selectedIcon: Icon(HugeIconsSolid.note01),
            label: 'Filings',
          ),
        ],
      ),
    );
  }

  Widget _tabView(ScreenerCompanyPage page) {
    final sections = switch (_tab) {
      _CompanyTab.overview => _overviewSections(page),
      _CompanyTab.financials => _financialSections(page),
      _CompanyTab.shareholding => _shareholdingSections(page),
      _CompanyTab.peers => _peerSections(page),
      _CompanyTab.filings => _filingSections(page),
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        key: PageStorageKey<String>('company-${_tab.name}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, SharePerksSpacing.lg),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => sections[index](context),
      ),
    );
  }

  // ─── Overview tab ──────────────────────────────────────────────────────────

  List<WidgetBuilder> _overviewSections(ScreenerCompanyPage page) {
    final data = page.data;
    final about = data.profile.description;
    return [
      (context) => _card(
        child: ScreenerHeader(
          profile: data.profile,
          quote: data.quote,
          isin: page.isin,
        ),
      ),
      if (about != null)
        (context) => _section(
          title: 'About',
          contentPadding: const EdgeInsets.all(14),
          child: _ExpandableText(text: about),
        ),
      (context) => _section(
        title: 'Key Metrics',
        caption: 'Figures in ₹ crore unless noted',
        trailing: _consolidationToggle(compact: true),
        child: ScreenerOverviewStats(data: data),
      ),
      (context) => _section(
        title: 'Price Chart',
        contentPadding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: ScreenerPriceChart(
          chart: _filteredChart ?? data.chart,
          activeRange: _chartRange,
          onSelectRange: _updateChart,
        ),
      ),
      (context) => _section(
        title: 'Analysis',
        caption: 'Valuation & cash flow metrics',
        contentPadding: EdgeInsets.zero,
        child: ScreenerAnalysis(
          priceRatios: data.priceRatios,
          financialMetrics: data.financialMetrics,
        ),
      ),
    ];
  }

  // ─── Financials tab ────────────────────────────────────────────────────────

  List<WidgetBuilder> _financialSections(ScreenerCompanyPage page) {
    return [
      (context) => _consolidationToggle(),
      if (page.quarterly != null && !page.quarterly!.isEmpty)
        (context) => _section(
          title: 'Quarterly Results',
          caption: _statementCaption(page.quarterly!),
          contentPadding: EdgeInsets.zero,
          child: NestedFinancialTable(statement: page.quarterly!),
        ),
      if (page.profitAndLoss != null && !page.profitAndLoss!.isEmpty)
        (context) => _section(
          title: 'Profit & Loss',
          caption: _statementCaption(page.profitAndLoss!),
          contentPadding: EdgeInsets.zero,
          child: NestedFinancialTable(statement: page.profitAndLoss!),
        ),
      if (page.balanceSheet != null && !page.balanceSheet!.isEmpty)
        (context) => _section(
          title: 'Balance Sheet',
          caption: _statementCaption(page.balanceSheet!),
          contentPadding: EdgeInsets.zero,
          child: NestedFinancialTable(statement: page.balanceSheet!),
        ),
      if (page.cashFlow != null && !page.cashFlow!.isEmpty)
        (context) => _section(
          title: 'Cash Flow',
          caption: _cfCaption(page.cashFlow!),
          contentPadding: EdgeInsets.zero,
          child: NestedCashFlowTable(cashFlow: page.cashFlow!),
        ),
      (context) => _section(
        title: 'Financial Ratios',
        caption: 'Figures in %',
        contentPadding: EdgeInsets.zero,
        child: ScreenerRatiosTable(ratios: page.data.ratios),
      ),
      if (page.profitAndLoss?.longTermMetrics != null)
        (context) => _longTermMetricsCard(page.profitAndLoss!.longTermMetrics!),
      if (!page.data.segments.isEmpty)
        (context) => _section(
          title: 'Revenue by Segment',
          caption: 'Figures in ₹',
          contentPadding: EdgeInsets.zero,
          child: ScreenerSegmentsTable(segments: page.data.segments),
        ),
    ];
  }

  // ─── Shareholding tab ──────────────────────────────────────────────────────

  List<WidgetBuilder> _shareholdingSections(ScreenerCompanyPage page) {
    return [
      (context) => page.data.shareholding.isEmpty
          ? _unavailable('Shareholding Pattern')
          : _section(
              title: 'Shareholding Pattern',
              caption: 'Quarterly · % of total shares',
              contentPadding: EdgeInsets.zero,
              child: ScreenerShareholdingTable(
                shareholding: page.data.shareholding,
              ),
            ),
    ];
  }

  // ─── Peers tab ─────────────────────────────────────────────────────────────

  List<WidgetBuilder> _peerSections(ScreenerCompanyPage page) {
    return [
      (context) => page.data.peers.peers.isEmpty
          ? _unavailable('Peer Comparison')
          : _section(
              title: 'Peer Comparison',
              caption: '${page.data.peers.others.length} peers',
              contentPadding: EdgeInsets.zero,
              child: ScreenerPeersTable(peers: page.data.peers),
            ),
    ];
  }

  // ─── Filings tab ───────────────────────────────────────────────────────────

  List<WidgetBuilder> _filingSections(ScreenerCompanyPage page) {
    return [
      (context) => _section(
        title: 'Documents & Announcements',
        child: ScreenerDocumentsSection(documents: page.data.documents),
      ),
      (context) => _section(
        title: 'Corporate Actions',
        child: ScreenerCorporateActionsSection(
          actions: page.data.corporateActions,
        ),
      ),
    ];
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        border: Border.all(color: SharePerksColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        child: child,
      ),
    );
  }

  Widget _section({
    required String title,
    String? caption,
    Widget? trailing,
    EdgeInsets contentPadding = const EdgeInsets.all(12),
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        border: Border.all(color: SharePerksColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: SharePerksFonts.albertSans,
                          color: SharePerksColors.textPrimaryLight,
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 10,
                            color: SharePerksColors.textSecondaryLight,
                            fontFamily: SharePerksFonts.inter,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: SharePerksColors.borderLight),
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
  }

  Widget _longTermMetricsCard(ScreenerLongTermMetrics m) {
    final metrics = <_MetricTile>[
      if (m.revenueCagr != null)
        _MetricTile('Revenue CAGR', '${m.revenueCagr!.toStringAsFixed(2)}%'),
      if (m.patCagr != null)
        _MetricTile('PAT CAGR', '${m.patCagr!.toStringAsFixed(2)}%'),
      if (m.epsCagr != null)
        _MetricTile('EPS CAGR', '${m.epsCagr!.toStringAsFixed(2)}%'),
      if (m.patMarginExpansionPp != null)
        _MetricTile(
          'PAT Margin Δ',
          '${m.patMarginExpansionPp!.toStringAsFixed(2)} pp',
        ),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();

    return _section(
      title: 'Long-Term Metrics',
      caption:
          '${m.fromFiscalYear ?? ''} – ${m.toFiscalYear ?? ''} (${m.periods ?? 0} years)',
      contentPadding: const EdgeInsets.all(14),
      child: Row(
        children: [
          for (final t in metrics)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: SharePerksColors.textSecondaryLight,
                        fontFamily: SharePerksFonts.inter,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: SharePerksFonts.albertSans,
                        color: SharePerksColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statementCaption(ScreenerStatement s) {
    final consolidation = s.isStandalone ? 'Standalone' : 'Consolidated';
    return '$consolidation · figures in ₹ Cr';
  }

  String _cfCaption(ScreenerCashFlow cf) {
    final consolidation = cf.isStandalone ? 'Standalone' : 'Consolidated';
    return '$consolidation · figures in ₹ Cr';
  }

  Widget _unavailable(String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            HugeIconsSolid.packageOpen,
            size: 40,
            color: SharePerksColors.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            '$title not available',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SharePerksColors.textSecondaryLight,
              fontFamily: SharePerksFonts.inter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _consolidationToggle({bool compact = false}) {
    Widget chip(String label, String short, Consolidation value) {
      final selected = _consolidation == value;
      final child = GestureDetector(
        onTap: () => _setConsolidation(value),
        child: Container(
          alignment: Alignment.center,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? SharePerksColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(CompanyRadii.sm),
          ),
          child: Text(
            compact ? short : label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : SharePerksColors.textSecondaryLight,
            ),
          ),
        ),
      );
      return compact ? child : Expanded(child: child);
    }

    return Container(
      padding: EdgeInsets.all(compact ? 3 : 4),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          chip('Standalone', 'Stand.', Consolidation.standalone),
          chip('Consolidated', 'Consol.', Consolidation.consolidated),
        ],
      ),
    );
  }

  Widget _errorView(CompanyApiException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SharePerksSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error.isNotFound
                  ? HugeIconsSolid.packageOpen
                  : HugeIconsStroke.alert02,
              size: 56,
              color: SharePerksColors.textSecondaryLight,
            ),
            const SizedBox(height: SharePerksSpacing.md),
            Text(
              error.isNotFound
                  ? 'Company not found'
                  : 'Could not load company details',
              style: const TextStyle(
                fontFamily: SharePerksFonts.albertSans,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SharePerksColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.isNotFound
                  ? 'We have no data for ${widget.symbol.toUpperCase()}.'
                  : error.displayMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
            if (!error.isNotFound) ...[
              const SizedBox(height: SharePerksSpacing.md),
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

enum _CompanyTab { overview, financials, shareholding, peers, filings }

class _MetricTile {
  const _MetricTile(this.label, this.value);
  final String label;
  final String value;
}

/// Shows 3 lines of text by default with a "Read more" button to expand
/// to the full text, and "Read less" to collapse back.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: SharePerksColors.textPrimaryLight,
            fontFamily: SharePerksFonts.inter,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Read less' : 'Read more',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SharePerksColors.primary,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 14,
                color: SharePerksColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
