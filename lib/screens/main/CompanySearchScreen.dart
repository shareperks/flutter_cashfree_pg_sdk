import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/services/company/company_data.service.dart';
import 'package:shareperks/utils/company_format.dart';
import 'package:soui/elements/SpScafold.dart';

/// Type-ahead over the listed-company universe, feeding
/// [RouteNames.COMPANY_DETAILS_SCREEN].
///
/// Search runs against a symbol master the service keeps cached for 24 hours,
/// so it answers in single-digit milliseconds and is safe to call while the
/// user types — after debouncing.
class CompanySearchScreen extends StatefulWidget {
  const CompanySearchScreen({super.key});

  @override
  State<CompanySearchScreen> createState() => _CompanySearchScreenState();
}

class _CompanySearchScreenState extends State<CompanySearchScreen> {
  /// One letter matches most of the market; two is where results start being
  /// worth showing.
  static const int _minQueryLength = 2;

  /// Text is unreadable in very long lines, so the page keeps a column even on
  /// a tablet or in landscape.
  static const double _maxContentWidth = 560;

  /// The symbols the service is warmed with, offered as a starting point so
  /// the empty state is not a blank screen.
  static const List<String> _popular = [
    'ITC',
    'RELIANCE',
    'TCS',
    'HDFCBANK',
    'INFY',
    'HINDUNILVR',
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  /// Guards against a slow early request landing after a faster later one and
  /// overwriting newer results.
  int _requestId = 0;

  List<SearchHit> _hits = const [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String? _lastTrackedTerm;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = value.trim();
    setState(() => _query = query);

    _debounce?.cancel();
    if (query.length < _minQueryLength) {
      setState(() {
        _hits = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    try {
      final hits = await CompanyDataService.search(query, limit: 20);
      if (!mounted || id != _requestId) return;
      setState(() {
        _hits = hits;
        _loading = false;
        _error = null;
      });
      _track(query, hits.length);
    } on CompanyApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = e.displayMessage;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = 'Search is unavailable right now.';
      });
    }
  }

  void _track(String query, int resultCount) {
    if (query == _lastTrackedTerm) return;
    _lastTrackedTerm = query;
    trackAction(AnalyticsEvent.search, {
      'label': 'Search Company',
      'search_term': query,
      'query': query,
      'result_count': resultCount,
      'source': 'company_search_screen',
    });
  }

  void _open(String symbol) {
    context.pushNamed(
      RouteNames.COMPANY_DETAILS_SCREEN,
      extra: {'symbol': symbol},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        backgroundColor: SharePerksColors.primary,
        leading: const AppBackButton(),
        toolbarHeight: 40,
        title: const Text('Search Company'),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Idle, the search sits in the upper third the way the web page's
          // hero does; typing lifts it to the top so the results own the
          // screen. Animating the gap rather than swapping layouts keeps the
          // field's element — and so the keyboard and the caret — alive.
          final searching = _query.length >= _minQueryLength;
          final topGap = searching ? 6.0 : constraints.maxHeight * 0.10;

          return Center(
            child: SizedBox(
              // Wide screens get a column, not a stretched row of text. An
              // explicit width rather than a max constraint: the Column
              // stretches its children, and under loose constraints that would
              // otherwise resolve against whichever child happens to be widest.
              width: math.min(constraints.maxWidth, _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    height: topGap,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: searching
                        ? const SizedBox(width: double.infinity)
                        : _hero(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _searchField(),
                  ),
                  Expanded(child: _results()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The headline the web page opens with, set for a phone.
  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SharePerksColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(CompanyRadii.md),
            ),
            child: const Icon(
              HugeIconsSolid.analyticsUp,
              size: 22,
              color: SharePerksColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Research any\n'),
                TextSpan(
                  text: 'listed Indian company',
                  style: TextStyle(color: SharePerksColors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SharePerksFonts.albertSans,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: SharePerksColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Financials, ratios, shareholding, pledge history and peers — '
            'in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: SharePerksColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: true,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.characters,
      onChanged: _onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Try ITC, HDFCBANK, TCS…',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: SharePerksColors.textSecondaryLight,
        ),
        filled: true,
        fillColor: SharePerksColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _fieldBorder(SharePerksColors.borderLight),
        enabledBorder: _fieldBorder(SharePerksColors.borderLight),
        focusedBorder: _fieldBorder(SharePerksColors.primary),
        prefixIcon: const Icon(
          HugeIconsStroke.search01,
          size: 18,
          color: SharePerksColors.textSecondaryLight,
        ),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  HugeIconsStroke.cancelCircle,
                  size: 18,
                  color: SharePerksColors.textSecondaryLight,
                ),
                onPressed: () {
                  _controller.clear();
                  _onChanged('');
                  _focus.requestFocus();
                },
              ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(CompanyRadii.md),
    borderSide: BorderSide(color: color),
  );

  Widget _results() {
    if (_query.length < _minQueryLength) return _idleState();

    if (_loading && _hits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 10),
            Text(
              'Searching the listed universe…',
              style: TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _message(
        icon: HugeIconsStroke.alert02,
        title: 'Could not search',
        detail: _error!,
        action: TextButton(
          onPressed: () => _search(_query),
          child: const Text('Try again'),
        ),
      );
    }

    if (_hits.isEmpty) {
      return _message(
        icon: HugeIconsSolid.packageOpen,
        title: 'No companies found',
        detail: 'Nothing matches "$_query". Try a different name or symbol.',
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      // One extra item for the count caption above the first result.
      itemCount: _hits.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) return _resultCount();
        return _hitTile(_hits[index - 1]);
      },
    );
  }

  Widget _resultCount() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        _hits.length == 1
            ? '1 company matches "$_query"'
            : '${_hits.length} companies match "$_query"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: SharePerksColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _hitTile(SearchHit hit) {
    final codes = <String>[
      if (hit.nseCode != null) 'NSE: ${hit.nseCode}',
      if (hit.bseCode != null) 'BSE: ${hit.bseCode}',
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(CompanyRadii.md),
      onTap: () => _open(hit.symbol),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SharePerksColors.backgroundLight,
          borderRadius: BorderRadius.circular(CompanyRadii.md),
          border: Border.all(color: SharePerksColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(CompanyRadii.sm),
              ),
              child: Text(
                companyInitials(hit.name, hit.symbol),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SharePerksColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SharePerksColors.textPrimaryLight,
                    ),
                  ),
                  if (codes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      codes.join('  ·  '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              HugeIconsSolid.arrowRight01,
              size: 15,
              color: SharePerksColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _idleState() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        const Text(
          'POPULAR',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final symbol in _popular)
              GestureDetector(
                onTap: () => _open(symbol),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SharePerksColors.surfaceLight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: SharePerksColors.borderLight),
                  ),
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SharePerksColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          _query.isEmpty
              ? 'Search by company name, NSE symbol or BSE code.'
              : 'Keep typing — at least $_minQueryLength characters.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SharePerksSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SharePerksColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: SharePerksFonts.albertSans,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SharePerksColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
