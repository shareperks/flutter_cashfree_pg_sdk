import 'package:flutter/material.dart';
import 'package:shareperks/components/NetworkLogo.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Company header with logo, name, sector pills, price, change %, and
/// 52-week range bar — Section 1 of the implementation guide.
class ScreenerHeader extends StatelessWidget {
  const ScreenerHeader({
    super.key,
    required this.profile,
    required this.quote,
    this.isin,
  });

  final ScreenerProfile profile;
  final ScreenerQuote quote;
  final ScreenerIsin? isin;

  @override
  Widget build(BuildContext context) {
    final price = quote.currentPrice;
    final change = quote.change;
    final isPositive = change != null && !change.startsWith('-');
    final logoUrl = isin?.logoUrl;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + Name + Sector
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _logo(logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: SharePerksFonts.albertSans,
                        color: SharePerksColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (profile.sector != null) _pill(profile.sector!),
                        if (profile.nseCode != null)
                          _pill('NSE: ${profile.nseCode}'),
                        if (profile.bseCode != null)
                          _pill('BSE: ${profile.bseCode}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Price + Change
          if (price != null) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(
                  '₹${_formatPrice(price)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: SharePerksFonts.albertSans,
                    color: SharePerksColors.textPrimaryLight,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isPositive
                                  ? SharePerksColors.success
                                  : SharePerksColors.error)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(CompanyRadii.sm),
                    ),
                    child: Text(
                      isPositive ? '+$change' : change,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: SharePerksFonts.inter,
                        color: isPositive
                            ? SharePerksColors.success
                            : SharePerksColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            if (quote.tradetime != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatDateTime(quote.tradetime!),
                style: const TextStyle(
                  fontSize: 10,
                  color: SharePerksColors.textSecondaryLight,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 52-week range bar
            if (quote.rangePct != null)
              _rangeBar(quote.rangePct!, quote.low52, quote.high52),
          ],
          // Industry + Website
          if (profile.industry != null || profile.website != null) ...[
            const SizedBox(height: 16),
            if (profile.industry != null)
              _infoRow('Industry', profile.industry!),
            if (profile.website != null)
              _infoRow('Website', 'https://${profile.website}'),
          ],
        ],
      ),
    );
  }

  Widget _logo(String? url) {
    if (url == null || url.isEmpty) {
      return _initialsAvatar();
    }
    return NetworkLogo(
      imageUrl: url,
      width: 56,
      height: 56,
      borderRadius: SharePerksRadii.md,
      fit: BoxFit.cover,
      svgFit: BoxFit.contain,
      padding: const EdgeInsets.all(6),
      backgroundColor: Colors.white,
      errorWidget: _initialsAvatar(),
    );
  }

  Widget _initialsAvatar() {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharePerksColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
      ),
      child: Text(
        profile.initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SharePerksColors.primary,
          fontFamily: SharePerksFonts.albertSans,
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SharePerksColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: SharePerksColors.primary,
          fontFamily: SharePerksFonts.inter,
        ),
      ),
    );
  }

  Widget _rangeBar(double pct, double? low, double? high) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '52-Week Range',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Clamp marker position to keep it within bounds.
            final markerPos = (pct / 100 * width).clamp(8.0, width - 8.0);
            return SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Bar
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEF4444),
                            Color(0xFFF59E0B),
                            Color(0xFF22C55E),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Marker
                  Positioned(
                    left: markerPos - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: SharePerksColors.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SharePerksColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              low != null ? '₹${_formatPrice(low)}' : '—',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
            Text(
              high != null ? '₹${_formatPrice(high)}' : '—',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: SharePerksColors.textSecondaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: SharePerksColors.textPrimaryLight,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
