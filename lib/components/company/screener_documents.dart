import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/finance_screener_models.dart';

/// Documents & announcements section — Section 15 of the screener guide.
///
/// Shows a grid of cards for announcements, credit ratings, transcripts, and
/// presentations. Each card shows a category badge, description (2-line
/// clamp), date, and a "View PDF" link if available. Shows the first 3 items
/// by default with a "View All" expand per section.
class ScreenerDocumentsSection extends StatelessWidget {
  const ScreenerDocumentsSection({super.key, required this.documents});

  final ScreenerDocuments documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No documents or announcements available.',
          style: TextStyle(
            fontSize: 12,
            color: SharePerksColors.textSecondaryLight,
            fontFamily: SharePerksFonts.inter,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.announcements.isNotEmpty) ...[
          _sectionTitle('Announcements'),
          const SizedBox(height: SharePerksSpacing.sm + 2),
          _DocumentGroup(documents: documents.announcements),
          const SizedBox(height: SharePerksSpacing.md),
        ],
        if (documents.creditRatings.isNotEmpty) ...[
          _sectionTitle('Credit Ratings'),
          const SizedBox(height: SharePerksSpacing.sm + 2),
          _DocumentGroup(documents: documents.creditRatings),
          const SizedBox(height: SharePerksSpacing.md),
        ],
        if (documents.transcripts.isNotEmpty) ...[
          _sectionTitle('Transcripts'),
          const SizedBox(height: SharePerksSpacing.sm + 2),
          _DocumentGroup(documents: documents.transcripts),
          const SizedBox(height: SharePerksSpacing.md),
        ],
        if (documents.presentations.isNotEmpty) ...[
          _sectionTitle('Presentations'),
          const SizedBox(height: SharePerksSpacing.sm + 2),
          _DocumentGroup(documents: documents.presentations),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: SharePerksColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: SharePerksFonts.albertSans,
            color: SharePerksColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

// ── document group with expand ───────────────────────────────────────────────

class _DocumentGroup extends StatefulWidget {
  const _DocumentGroup({required this.documents});

  final List<ScreenerDocument> documents;

  @override
  State<_DocumentGroup> createState() => _DocumentGroupState();
}

class _DocumentGroupState extends State<_DocumentGroup> {
  bool _expanded = false;
  static const _defaultCount = 3;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded || widget.documents.length <= _defaultCount
        ? widget.documents
        : widget.documents.sublist(0, _defaultCount);
    final hiddenCount = widget.documents.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          _docCard(visible[i]),
          if (i < visible.length - 1) const SizedBox(height: 6),
        ],
        if (hiddenCount > 0 || _expanded) ...[
          const SizedBox(height: SharePerksSpacing.sm + 2),
          _expandButton(hiddenCount),
        ],
      ],
    );
  }

  Widget _docCard(ScreenerDocument doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharePerksColors.surfaceLight,
        borderRadius: BorderRadius.circular(CompanyRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          if (doc.category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(CompanyRadii.sm),
              ),
              child: Text(
                doc.category!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: SharePerksColors.primary,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Description (2-line clamp)
          Text(
            doc.description.isEmpty ? '—' : doc.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: SharePerksColors.textPrimaryLight,
              fontFamily: SharePerksFonts.inter,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Date + View PDF link
          Row(
            children: [
              if (doc.date != null)
                Flexible(
                  child: Text(
                    doc.date!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: SharePerksColors.textSecondaryLight,
                      fontFamily: SharePerksFonts.inter,
                    ),
                  ),
                ),
              if (doc.date != null && doc.pdfUrl != null)
                const SizedBox(width: 8),
              if (doc.pdfUrl != null)
                GestureDetector(
                  onTap: () => _openPdf(doc.pdfUrl!),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 12,
                        color: SharePerksColors.primary,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'View PDF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: SharePerksColors.primary,
                          fontFamily: SharePerksFonts.inter,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPdf(String url) {
    // URL opening is handled by the parent screen via a URL launcher.
    // This widget only renders the affordance.
  }

  Widget _expandButton(int hiddenCount) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SharePerksColors.surfaceLight,
          borderRadius: BorderRadius.circular(CompanyRadii.sm),
          border: Border.all(color: SharePerksColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded ? 'Show Less' : 'View All ($hiddenCount more)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SharePerksColors.primary,
                fontFamily: SharePerksFonts.inter,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: SharePerksColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
