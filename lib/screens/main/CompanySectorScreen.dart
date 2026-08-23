import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';
import 'package:shareperks/repository/services/company/company_data.service.dart';
import 'package:soui/elements/SpScafold.dart';

/// Every company filed under one sector / industry — the app's version of the
/// web page's `/sector/:value`.
///
/// `GET /companies/classification` answers with symbols only, so the screen
/// shows them as chips rather than pretending to a richer list it would have to
/// fetch one company at a time.
class CompanySectorScreen extends StatefulWidget {
  const CompanySectorScreen({
    super.key,
    required this.group,
    required this.value,
  });

  final ClassificationGroup group;

  /// The exact string the service classifies by, e.g. `Diversified FMCG`.
  final String value;

  @override
  State<CompanySectorScreen> createState() => _CompanySectorScreenState();
}

class _CompanySectorScreenState extends State<CompanySectorScreen> {
  bool _loading = true;
  String? _error;
  List<String> _symbols = const [];
  String _filter = '';

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
      final symbols = await CompanyDataService.classification(
        widget.group,
        widget.value,
      );
      if (!mounted) return;
      setState(() {
        // Upstream order is arbitrary; alphabetical is the only order a reader
        // can navigate by eye.
        _symbols = [...symbols]..sort();
        _loading = false;
      });
    } on CompanyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.displayMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This classification is unavailable right now.';
        _loading = false;
      });
    }
  }

  String get _groupLabel => switch (widget.group) {
    ClassificationGroup.sector => 'Sector',
    ClassificationGroup.industry => 'Industry',
    ClassificationGroup.subIndustry => 'Sub-industry',
    ClassificationGroup.macroSector => 'Macro sector',
  };

  List<String> get _visible {
    if (_filter.isEmpty) return _symbols;
    final needle = _filter.toUpperCase();
    return _symbols.where((s) => s.toUpperCase().contains(needle)).toList();
  }

  void _open(String symbol) {
    // `pushNamed`, not `replace`: a reader drills sector → company → back to
    // the sector list, and expects the list to still be there.
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
        title: Text(_groupLabel),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (_error != null) return _errorView(_error!);
          return _list();
        },
      ),
    );
  }

  Widget _list() {
    final visible = _visible;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, SharePerksSpacing.lg),
      children: [
        Text(
          _groupLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.value,
          style: const TextStyle(
            fontFamily: SharePerksFonts.albertSans,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: SharePerksColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _symbols.length == 1
              ? '1 company in this ${_groupLabel.toLowerCase()}'
              : '${_symbols.length} companies in this ${_groupLabel.toLowerCase()}',
          style: const TextStyle(
            fontSize: 12,
            color: SharePerksColors.textSecondaryLight,
          ),
        ),
        if (_symbols.length > 12) ...[
          const SizedBox(height: SharePerksSpacing.md),
          TextField(
            onChanged: (value) => setState(() => _filter = value.trim()),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter symbols',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: SharePerksColors.textSecondaryLight,
              ),
              prefixIcon: const Icon(HugeIconsStroke.search01, size: 16),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 32,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: SharePerksColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CompanyRadii.md),
                borderSide: const BorderSide(
                  color: SharePerksColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CompanyRadii.md),
                borderSide: const BorderSide(
                  color: SharePerksColors.borderLight,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: SharePerksSpacing.md),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                _symbols.isEmpty
                    ? 'No companies returned for this classification.'
                    : 'No symbol matches "$_filter".',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: SharePerksColors.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final symbol in visible)
                GestureDetector(
                  onTap: () => _open(symbol),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: SharePerksColors.surfaceLight,
                      borderRadius: BorderRadius.circular(CompanyRadii.sm),
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
      ],
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SharePerksSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              HugeIconsStroke.alert02,
              size: 48,
              color: SharePerksColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SharePerksColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
