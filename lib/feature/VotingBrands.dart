import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shareperks/components/loader/voting_brands_loader.dart';
import 'package:shareperks/components/VotBrand.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/voting_listing_model.dart';
import 'package:shareperks/repository/services/listing/voating.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/border_card.dart';

class VotingBrands extends StatefulWidget {
  const VotingBrands({super.key});

  @override
  State<VotingBrands> createState() => _VotingBrandsState();
}

class _VotingBrandsState extends State<VotingBrands> {
  VotingListingResponse? data;
  bool _isError = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? selectedIndex;

  Future<void> loadData() async {
    try {
      _isError = false;
      data = await VotingService.fetchVotingListing();
    } catch (e) {
      _isError = true;
    } finally {
      setState(() {
        _isLoading = false;
        _preselectSubmittedVote();
      });
    }
  }

  void _preselectSubmittedVote() {
    if (selectedIndex != null) return;
    final submittedId = data?.item?.mySubmit?.id;
    final brands = data?.item?.brands;
    if (submittedId == null || brands == null) return;
    final idx = brands.indexWhere((b) => b.id == submittedId);
    if (idx >= 0) selectedIndex = idx;
  }

  Future<void> _showVoteSuccessDialog(String brandName) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final titleStyle = TextStyle(
          fontFamily: SharePerksFonts.albertSans,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: const Color(0xFF111827),
        );
        final bodyStyle = TextStyle(
          fontFamily: SharePerksFonts.inter,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.45,
          color: const Color(0xFF333333),
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Your vote was submitted', style: titleStyle),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanks for taking part in SharePerks voting.',
                style: bodyStyle,
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    const TextSpan(text: 'We recorded your choice for '),
                    TextSpan(
                      text: brandName,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(
                      text:
                          '. Results will reflect after voting ends. '
                          'You can vote again until voting closes if your campaign allows it.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                foregroundColor: SharePerksColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitVot() async {
    if (selectedIndex == null) {
      Fluttertoast.showToast(msg: "Please select a brand");
      return;
    }
    try {
      setState(() => _isSubmitting = true);
      final votId = data?.item?.id ?? "";
      final brandId = data?.item?.brands?[selectedIndex!].id ?? "";
      final pickedName =
          data?.item?.brands?[selectedIndex!].name ?? 'this brand';

      final response = await VotingService.submitVot(votId, brandId);
      final isRevote = data?.item?.mySubmit?.id == brandId;
      trackAction(AnalyticsEvent.votingBrandSelected, {
        'brand_id': brandId,
        'is_revote': isRevote,
      });
      final confirmedName =
          response.item?.brand?.name ??
          response.item?.brand?.ticker ??
          pickedName;

      await _showVoteSuccessDialog(confirmedName);
      if (mounted) loadData();
    } catch (e) {
      _isError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  // sec to hours convert 3 ,2,1 like this

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const VotingBrandsLoader();
    }
    if (!(data?.item?.isActive ?? false)) {
      return SizedBox.shrink();
    }
    if (_isError) {
      return SizedBox.shrink();
    }

    final votingItem = data?.item;
    final daysRemaining = votingItem?.daysRemaining ?? 0;
    final remainingLabel = votingItem?.remainingDaysLabel ?? 'Voting open';

    return BorderCard(
      borderWidth: 1,
      borderRadius: 16,
      color: SharePerksColors.primary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Vote for  Your ',
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 18,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: 'Favorite',
                        style: TextStyle(
                          color: const Color(0xFFFF4AA7),
                          fontSize: 18,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '\nBrands Now!',
                        style: TextStyle(
                          color: const Color(0xFF6400E0),
                          fontSize: 18,
                          fontFamily: SharePerksFonts.albertSans,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$daysRemaining',
                      style: TextStyle(
                        color: const Color(0xFF6400E0),
                        fontSize: 28,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      remainingLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: const Color(0xFF898989),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      'Vote now.',
                      style: TextStyle(
                        color: const Color(0xFF6400E0),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 10,
                  children: [
                    SizedBox(width: 8),
                    ...List.generate(data?.item?.brands?.length ?? 0, (index) {
                      VotingListingBrand? brand = data?.item?.brands?[index];
                      final isSelected = index == selectedIndex;
                      final isPreviouslyVoted =
                          data?.item?.mySubmit?.id != null &&
                          data?.item?.mySubmit?.id == brand?.id;

                      return VotBrandCard(
                        image: imageUrl(brand?.image ?? ""),
                        name: brand?.name ?? "--",
                        ticker: brand?.ticker ?? "--",
                        isSelected: isSelected,
                        isPreviouslyVoted: isPreviouslyVoted,
                        onTap: () {
                          setState(() {
                            if (isPreviouslyVoted) {
                              selectedIndex = index;
                              return;
                            }
                            selectedIndex = isSelected ? null : index;
                          });
                        },
                      );
                    }),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitVot,
                child: Text(_isSubmitting ? 'Submitting...' : 'Vote now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
