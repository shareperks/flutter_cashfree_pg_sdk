import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/company_data_model.dart';

/// One place for every empty state on the company details screen.
///
/// Every numeric field from the company-data-service is nullable and `null`
/// means "upstream has no value", never zero — so everything below renders an
/// em dash rather than falling back to `0`.
const String kEmDash = '—';

String companyDash<T>(T? value, String Function(T value) render) =>
    value == null ? kEmDash : render(value);

/// `1234567.5` → `12,34,567.50` (Indian digit grouping).
String formatIndianNumber(double value, {int decimals = 2}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  final formatted = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  return negative ? '-$formatted' : formatted;
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  var remaining = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (remaining.isNotEmpty) {
    if (remaining.length <= 2) {
      groups.insert(0, remaining);
      break;
    }
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  return '${groups.join(',')},$lastThree';
}

/// `338045.04` → `₹ 3,38,045 Cr`. Values arrive already in crore.
String fmtCr(double? value) =>
    companyDash(value, (v) => '₹ ${formatIndianNumber(v, decimals: 0)} Cr');

/// `29.01` → `29.0%`. The service already multiplied by 100 — never again.
String fmtPct(double? value, {int decimals = 1}) =>
    companyDash(value, (v) => '${formatIndianNumber(v, decimals: decimals)}%');

String fmtNum(double? value, {int decimals = 2}) =>
    companyDash(value, (v) => formatIndianNumber(v, decimals: decimals));

String fmtRupees(double? value, {int decimals = 2}) =>
    companyDash(value, (v) => '₹ ${formatIndianNumber(v, decimals: decimals)}');

/// Large counts read better abbreviated: `12245059584` → `1,224.51 Cr`,
/// `450000` → `4.50 L`. Mirrors the web page's `fmtCompact`.
String fmtCompactCount(double? value) => companyDash(value, (v) {
  final abs = v.abs();
  if (abs >= 1e7) return '${formatIndianNumber(v / 1e7, decimals: 2)} Cr';
  if (abs >= 1e5) return '${formatIndianNumber(v / 1e5, decimals: 2)} L';
  return formatIndianNumber(v, decimals: 0);
});

/// `-0.53` → `-0.53%`, `1.2` → `+1.20%`.
String fmtSignedPct(double? value, {int decimals = 2}) =>
    companyDash(value, (v) {
      final sign = v > 0 ? '+' : '';
      return '$sign${formatIndianNumber(v, decimals: decimals)}%';
    });

/// Formats a statement cell by the unit its row declares.
///
/// Percent rows deliberately render bare numbers: a `%` on all 34 columns of a
/// quarterly table costs a character of column width per cell and says nothing
/// the row label cannot. The unit is shown once, next to the label — the same
/// trade the web page makes.
String fmtByUnit(double? value, FinancialUnit unit) => switch (unit) {
  FinancialUnit.cr => companyDash(
    value,
    (v) => formatIndianNumber(v, decimals: 0),
  ),
  FinancialUnit.pct || FinancialUnit.ratio => fmtNum(value, decimals: 2),
  FinancialUnit.count => companyDash(
    value,
    (v) => formatIndianNumber(v, decimals: 0),
  ),
};

/// The suffix shown after a row's label so its cells can stay bare.
String unitSuffix(FinancialUnit unit) => unit == FinancialUnit.pct ? ' %' : '';

/// Whether a statement row reports anything at all.
///
/// A P&L carries the union of every line item upstream models, so a
/// manufacturer gets a dozen bank-and-NBFC rows ("Interest Earned", "Fees And
/// Commission") that are zero in every period. They are not wrong, just
/// inapplicable — and inline they bury the rows a reader is scanning for.
bool rowHasData(FinancialRow row) =>
    row.values.any((value) => value != null && value != 0);

/// Statement lines a reader scans for first, rendered bold. Keys are the
/// service's stable upstream keys.
const Set<String> _headlineRowKeys = {
  'revenueFromOperations',
  'profitLossForPeriod',
  'profitBeforeTax',
  'operatingProfit',
  'ebitda',
  'eps',
  'EPS',
  'returnOnEquity',
  'returnOnCapital',
};

bool isHeadlineRow(String key) => _headlineRowKeys.contains(key);

/// `2026-08-21` → `21 Aug 2026`. Dates from the service are date-only ISO
/// strings, so they are parsed as UTC — a local parse shifts half of them back
/// a day.
String fmtIsoDate(String? iso) => companyDash(iso, (value) {
  final parts = value.split('T').first.split('-');
  if (parts.length < 3) return value;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return value;
  if (month < 1 || month > 12) return value;
  return '$day ${_months[month - 1]} $year';
});

/// `2026-08-21T15:50:43.000Z` → `21 Aug 2026, 3:50 pm`; a date-only string
/// falls back to [fmtIsoDate].
///
/// The clock is rendered exactly as it arrives — deliberately *not* converted
/// to the phone's zone. The service stamps IST wall-clock time with a `Z`, so
/// converting would push a 3:50 pm market close to 9:20 pm.
String fmtIsoDateTime(String? iso) => companyDash(iso, (value) {
  final parts = value.split('T');
  final date = fmtIsoDate(parts.first);
  if (parts.length < 2 || date == kEmDash) return date;

  final clock = parts[1].split(':');
  if (clock.length < 2) return date;
  final hour = int.tryParse(clock[0]);
  final minute = int.tryParse(clock[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return date;

  final suffix = hour < 12 ? 'am' : 'pm';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$date, $hour12:${minute.toString().padLeft(2, '0')} $suffix';
});

const List<String> _months = [
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

/// `ITC Ltd` → `IT`, `Tata Consultancy Services` → `TC`, for an avatar tile.
///
/// The corporate suffix carries no information and would otherwise dominate
/// every tile. BSE-only listings have numeric symbols and no usable words, so
/// the fallback takes the symbol's first characters as they are. Mirrors the
/// web page's `initials` helper.
String companyInitials(String name, String symbol) {
  final words = name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && RegExp('^[A-Za-z]').hasMatch(word))
      .where(
        (word) => !RegExp(
          r'^(ltd|limited|inc|corp|corporation|plc|co)\.?$',
          caseSensitive: false,
        ).hasMatch(word),
      )
      .toList();

  if (words.isEmpty) {
    final fallback = symbol.trim().isEmpty ? '?' : symbol.trim();
    return fallback.substring(0, fallback.length < 2 ? 1 : 2).toUpperCase();
  }
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length < 2 ? 1 : 2).toUpperCase();
  }
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

/// Axis-sized price: `269.8` → `270`, `12450` → `12.5K`, `152000` → `1.5L`.
///
/// A chart axis has about five characters to work with, and `1,52,000` is
/// seven before the rupee sign.
String fmtCompactPrice(double value) {
  final abs = value.abs();
  if (abs >= 1e5) return '${(value / 1e5).toStringAsFixed(1)}L';
  if (abs >= 1e4) return '${(value / 1e3).toStringAsFixed(0)}K';
  if (abs >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
  return value.toStringAsFixed(abs < 10 ? 1 : 0);
}

/// Axis-sized date: `2026-08-21` → `Aug 26`, or `2026` when [yearOnly].
String fmtAxisDate(String iso, {bool yearOnly = false}) {
  final parts = iso.split('T').first.split('-');
  if (parts.length < 2) return iso;
  final year = parts[0];
  if (yearOnly) return year;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return year;
  return '${_months[month - 1]} ${year.substring(year.length - 2)}';
}

/// `Mar 2018` → a sortable integer, so pledge rows (which arrive unsorted) can
/// be put in chronological order.
int periodOrder(String period) {
  final parts = period.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return 0;
  final month = _months.indexOf(parts[0]);
  final year = int.tryParse(parts[1]) ?? 0;
  return year * 12 + (month < 0 ? 0 : month);
}

Color signColor(double? value) {
  if (value == null || value == 0) return SharePerksColors.textSecondaryLight;
  return value > 0 ? SharePerksColors.success : SharePerksColors.error;
}

/// Where [price] sits inside the 52-week band, as `0…1`.
///
/// Null when the band cannot be drawn — a missing bound, or a high that is not
/// above the low (which upstream does publish for thinly traded symbols).
double? bandPosition(double? price, double? low, double? high) {
  if (price == null || low == null || high == null || high <= low) return null;
  return ((price - low) / (high - low)).clamp(0.0, 1.0);
}

/// Any promoter pledge is a risk signal, so it is coloured even when small:
/// amber below 10% of promoter holding, red at or above it.
Color pledgeToneColor(double? value) {
  if (value == null || value == 0) return SharePerksColors.textPrimaryLight;
  return value >= 10 ? SharePerksColors.error : SharePerksColors.warning;
}
