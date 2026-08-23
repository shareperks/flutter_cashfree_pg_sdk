import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/company/company_disclosures.dart';
import 'package:shareperks/components/company/company_growth_blocks.dart';
import 'package:shareperks/components/company/company_header.dart';
import 'package:shareperks/components/company/company_peers_view.dart';
import 'package:shareperks/components/company/company_price_chart.dart';
import 'package:shareperks/components/company/company_section.dart';
import 'package:shareperks/components/company/company_shareholding_view.dart';
import 'package:shareperks/components/loader/company_details_loader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/services/company/company_data.service.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/SpScafold.dart';

/// The five bottom-bar destinations the company details screen is split
/// across.
enum _CompanyTab { overview, financials, shareholding, peers, filings }

/// Screener-style company details: key metrics, price chart, quarterly and
/// annual statements, ratios, growth, shareholding, peers, segments, filings
/// and corporate actions.
///
/// **Why tabs rather than one long scroll.** The page carries five financial
/// tables plus shareholding and peers; rendered together that is several
/// thousand `Text` widgets laid out in a single pass, which is what made the
/// original single-column version stutter. Splitting the sections across a
/// bottom navigation bar means only one tab's widgets exist at a time, and
/// within a tab sections are built lazily as they scroll into view.
///
/// Data is still fetched once: `GET /companies/:symbol` returns all nine
/// sections in one round trip and lives in this state object, so switching
/// tabs is pure rendering and never re-hits the network.
class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key, required this.symbol});

  /// NSE symbol or BSE code, e.g. `ITC`, `M&M`, `543806`.
  final String symbol;

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  _CompanyTab _tab = _CompanyTab.overview;
  Consolidation _consolidation = Consolidation.standalone;

  bool _loading = true;
  CompanyApiException? _error;
  CompanyPage? _page;

  /// Formatted table rows, keyed by section. Converting a statement's numbers
  /// to strings is O(rows × columns); caching keeps it off every rebuild —
  /// otherwise a background fetch completing re-formats every visible table.
  final Map<String, List<CompanyTableRowData>> _rowsCache = {};

  List<SegmentPeriod>? _segments;
  CompanyDocuments? _documents;
  CompanyCorporateActions? _corporateActions;

  // Chart state lives here rather than inside the chart widget: the Overview
  // tab is rebuilt on every tab switch, and a self-loading chart would refetch
  // its history each time.
  CompanyChartRange _chartRange = CompanyChartRange.all.first;
  CompanyChart? _chart;
  bool _chartLoading = true;
  String? _chartError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _rowsCache.clear();
    });

    try {
      final page = await CompanyDataService.getPage(
        widget.symbol,
        consolidation: _consolidation,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
      _loadExtras();
      _loadChart(_chartRange);
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

  /// Extras are additive: if any of them fails the section simply does not
  /// render, and the page stands.
  void _loadExtras() {
    CompanyDataService.getSegments(widget.symbol, consolidation: _consolidation)
        .then((value) {
          if (mounted) setState(() => _segments = value);
        })
        .catchError((_) => null);

    CompanyDataService.getDocuments(widget.symbol)
        .then((value) {
          if (mounted) setState(() => _documents = value);
        })
        .catchError((_) => null);

    CompanyDataService.getCorporateActions(widget.symbol)
        .then((value) {
          if (mounted) setState(() => _corporateActions = value);
        })
        .catchError((_) => null);
  }

  Future<void> _loadChart(CompanyChartRange range) async {
    setState(() {
      _chartRange = range;
      _chartLoading = true;
      _chartError = null;
    });
    try {
      final now = DateTime.now().year;
      final chart = await CompanyDataService.getChart(
        widget.symbol,
        // The endpoint takes years, not dates — a date string is a 400.
        from: range.years == 0 ? null : now - range.years,
        to: range.years == 0 ? null : now,
      );
      if (!mounted) return;
      setState(() {
        _chart = chart;
        _chartLoading = false;
      });
    } on CompanyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _chartError = e.displayMessage;
        _chartLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chartError = 'Price history is unavailable right now.';
        _chartLoading = false;
      });
    }
  }

  Future<void> _setConsolidation(Consolidation value) async {
    if (value == _consolidation) return;
    setState(() {
      _consolidation = value;
      // Segment figures follow the same standalone/consolidated choice.
      _segments = null;
    });
    await _load();
  }

  /// The chart on its own page: zoomable, with volume and per-session OHLC.
  ///
  /// The series already on screen goes with it, so the page opens drawn.
  void _openFullChart(CompanyIdentity identity) {
    context.pushNamed(
      RouteNames.COMPANY_CHART_SCREEN,
      extra: {
        'symbol': identity.symbol,
        'name': identity.name,
        if (_chart != null && _chartRange.years > 0) ...{
          'chart': _chart,
          'years': _chartRange.years,
        },
      },
    );
  }

  /// Sector / industry chips open the companies filed under them — the app's
  /// equivalent of the web page's `/sector/:value` links.
  void _openClassification(CompanyClassification tag) {
    context.pushNamed(
      RouteNames.COMPANY_SECTOR_SCREEN,
      extra: {'group': tag.group, 'value': tag.value},
    );
  }

  bool _isUnavailable(String section) =>
      _page?.unavailable.contains(section) ?? false;

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final ready = !_loading && _error == null && page != null;

    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: const AppBackButton(),
        toolbarHeight: 40,
        title: Text(
          page?.overview.identity.symbol ?? widget.symbol.toUpperCase(),
        ),
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

  /// Material 3 bottom navigation — the standard Android pattern, themed to
  /// the app's purple.
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

  Widget _tabView(CompanyPage page) {
    final sections = switch (_tab) {
      _CompanyTab.overview => _overviewSections(page),
      _CompanyTab.financials => _financialSections(page),
      _CompanyTab.shareholding => _shareholdingSections(page),
      _CompanyTab.peers => _peerSections(page),
      _CompanyTab.filings => _filingSections(),
    };

    return RefreshIndicator(
      onRefresh: _load,
      // `itemBuilder` is what makes this lazy — a section is only built once it
      // scrolls into view, and the key restores each tab's scroll offset.
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

  List<WidgetBuilder> _overviewSections(CompanyPage page) {
    final about = page.overview.identity.about;
    return [
      // Named up front, the way the web page does it: a section that failed
      // upstream is otherwise indistinguishable from one a company never
      // published.
      if (page.unavailable.isNotEmpty)
        (context) => CompanyUnavailableBanner(
          sections: page.unavailable,
          onRetry: _load,
        ),
      (context) => CompanyIdentityCard(
        identity: page.overview.identity,
        metrics: page.overview.metrics,
        onTapClassification: _openClassification,
      ),
      (context) => CompanySection(
        title: 'Key Metrics',
        caption: 'Figures in ₹ crore unless noted',
        // The metrics themselves are standalone/consolidated figures, so the
        // switch belongs here too and not only on the Financials tab.
        trailing: _consolidationToggle(compact: true),
        child: CompanyStatGrid(metrics: page.overview.metrics),
      ),
      (context) => CompanyPriceChart(
        chart: _chart,
        loading: _chartLoading,
        error: _chartError,
        activeRange: _chartRange,
        onSelectRange: _loadChart,
        onRetry: () => _loadChart(_chartRange),
        onExpand: () => _openFullChart(page.overview.identity),
      ),
      (context) => CompanySection(
        title: 'Pros & Cons',
        child: CompanyProsAndCons(
          pros: page.overview.pros,
          cons: page.overview.cons,
        ),
      ),
      if (about != null)
        (context) => CompanySection(
          title: 'About',
          child: CompanyAboutText(about: about),
        ),
      if (page.overview.metrics.lastTradedAt != null)
        (context) => Center(
          child: Text(
            'Market data as on '
            '${fmtIsoDateTime(page.overview.metrics.lastTradedAt)}',
            style: const TextStyle(
              fontSize: 10,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
        ),
    ];
  }

  List<WidgetBuilder> _financialSections(CompanyPage page) {
    return [
      (context) => _consolidationToggle(),
      (context) => _statement(
        'Quarterly Results',
        page.quarterlyResults,
        'quarterlyResults',
      ),
      (context) =>
          _statement('Profit & Loss', page.profitAndLoss, 'profitAndLoss'),
      (context) =>
          _statement('Balance Sheet', page.balanceSheet, 'balanceSheet'),
      (context) => _statement('Cash Flow', page.cashFlow, 'cashFlow'),
      (context) => _statement('Ratios', page.ratios, 'ratios'),
      (context) => page.growth != null
          ? CompanySection(
              title: 'Compounded Growth',
              caption: 'Return on Equity is an average, not a CAGR',
              child: CompanyGrowthBlocks(growth: page.growth!),
            )
          : SectionUnavailable(title: 'Compounded Growth', onRetry: _load),
      if (_segments != null && _segments!.isNotEmpty)
        (context) => CompanySection(
          title: 'Segments',
          caption: 'Revenue and profit in ₹ crore',
          child: CompanySegmentsView(periods: _segments!),
        ),
    ];
  }

  List<WidgetBuilder> _shareholdingSections(CompanyPage page) {
    return [
      (context) => page.shareholding != null
          ? CompanySection(
              title: 'Shareholding Pattern',
              caption: page.shareholding!.period == ReportPeriod.quarterly
                  ? 'Quarterly · % of total shares'
                  : 'Annual · % of total shares',
              child: CompanyShareholdingView(data: page.shareholding!),
            )
          : SectionUnavailable(title: 'Shareholding Pattern', onRetry: _load),
    ];
  }

  List<WidgetBuilder> _peerSections(CompanyPage page) {
    return [
      (context) => page.peers != null
          ? CompanySection(
              title: 'Peer Comparison',
              caption:
                  'Same ${page.peers!.group} · ${page.peers!.peers.length} peers',
              child: CompanyPeersView(comparison: page.peers!),
            )
          : SectionUnavailable(title: 'Peer Comparison', onRetry: _load),
    ];
  }

  List<WidgetBuilder> _filingSections() {
    return [
      (context) => _documents != null
          ? CompanySection(
              title: 'Documents',
              child: CompanyDocumentsView(documents: _documents!),
            )
          : const CompanySection(
              title: 'Documents',
              child: SectionEmptyNote(message: 'Loading filings…'),
            ),
      (context) => _corporateActions != null
          ? CompanySection(
              title: 'Corporate Actions',
              child: CompanyCorporateActionsView(actions: _corporateActions!),
            )
          : const CompanySection(
              title: 'Corporate Actions',
              child: SectionEmptyNote(message: 'Loading corporate actions…'),
            ),
    ];
  }

  static const Widget _gap = SizedBox(height: SharePerksSpacing.md);

  /// A statement section, or a retry affordance when the service could not
  /// build it — a silently dropped section reads as "this company has no data".
  Widget _statement(String title, FinancialTable? table, String key) {
    if (table == null || table.isEmpty) {
      return SectionUnavailable(
        title: title,
        message: _isUnavailable(key)
            ? 'We could not load $title just now.'
            : 'No $title published for this company.',
        onRetry: _load,
      );
    }

    final consolidationLabel = table.consolidation == Consolidation.consolidated
        ? 'Consolidated'
        : 'Standalone';
    final rows = _rowsCache.putIfAbsent(key, () => _formatRows(table));

    return CompanySection(
      title: title,
      caption: switch (table) {
        final t when t.hasCroreRows => '$consolidationLabel · figures in ₹ Cr',
        final t when t.isAllPercent => '$consolidationLabel · figures in %',
        _ => consolidationLabel,
      },
      child: CompanyDataTable(
        columns: table.columns,
        scrollToLatest: true,
        rows: rows,
      ),
    );
  }

  /// Formats one statement, dropping the rows that report nothing in any
  /// period.
  ///
  /// Upstream models the union of every line item, so a manufacturer's P&L
  /// carries a dozen bank-only rows ("Interest Earned", "Fees And Commission")
  /// that are nil everywhere — 74 of the 118 rows in ITC's cash flow. They say
  /// nothing about the company, so they are not rendered at all.
  List<CompanyTableRowData> _formatRows(FinancialTable table) {
    // A table that is percentages end to end says so in its caption instead,
    // rather than repeating "%" down every label.
    final allPercent = table.isAllPercent;

    return [
      for (final row in table.rows)
        if (rowHasData(row))
          CompanyTableRowData(
            // Percent rows carry their unit here so the cells can stay bare.
            label: allPercent
                ? row.label
                : '${row.label}${unitSuffix(row.unit)}',
            highlight: isHeadlineRow(row.key),
            // Values are already aligned with columns by index.
            values: [
              for (final value in row.values) fmtByUnit(value, row.unit),
            ],
          ),
    ];
  }

  /// Standalone / consolidated. [compact] is the version that sits inside a
  /// section header; the full-width one heads the Financials tab.
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
            // Both full words do not fit beside a section title.
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
            _gap,
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
              _gap,
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
