import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/loader/MyReferralsListShimmer.dart';
import 'package:shareperks/components/category_search_sort_bar.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/models/referral_list_model.dart';
import 'package:shareperks/repository/services/listing/referral.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class MyReferralListScreen extends StatefulWidget {
  const MyReferralListScreen({super.key});

  @override
  State<MyReferralListScreen> createState() => _MyReferralListScreenState();
}

class _MyReferralListScreenState extends State<MyReferralListScreen> {
  /// Set from referral list API: `referrals.isNotEmpty`.
  bool _hasReferrals = false;

  bool _loading = true;
  bool _error = false;

  List<ReferralListEntry> _users = [];

  Future<void> loadData() async {
    try {
      _error = false;
      _users = await ReferralListingService.getAllReferrals();
      _hasReferrals = _users.isNotEmpty;
    } catch (e) {
      _error = true;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("My Referrals"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(18),
        width: MediaQuery.of(context).size.width,
        child: _loading
            ? const MyReferralsListShimmer()
            : _error
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Could not load referrals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: SharePerksFonts.albertSans,
                        fontSize: 16,
                        color: SharePerksColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = false;
                        });
                        loadData();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            : _hasReferrals
            ? _ReferralsListContent(data: _users)
            : const _NoReferralsView(),
      ),
    );
  }
}

class _NoReferralsView extends StatelessWidget {
  const _NoReferralsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              HugeIconsSolid.chatUser,
              size: 80,
              color: SharePerksColors.accent,
            ),
            const SizedBox(height: 20),
            Text(
              'No referrals yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 18,
                fontFamily: SharePerksFonts.albertSans,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Share your code with friends. When they join, they will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF898989),
                  fontSize: 14,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.REFER_CODE_SCREEN);
                },
                child: const Text('Get your refer code'),
              ),
            ),
            const SizedBox(height: 16),
            const ClickToHelp(),
            const SizedBox(height: 68),
          ],
        ),
      ),
    );
  }
}

bool _referralLooksPending(ReferralListEntry e) {
  if ((e.pendingStep ?? 0) > 0) return true;
  final s = (e.status ?? '').toLowerCase();
  return s.contains('pending');
}

bool _referralLooksSettled(ReferralListEntry e) {
  if ((e.pendingStep ?? 0) > 0) return false;
  final s = (e.status ?? '').toLowerCase().trim();
  if (s.isEmpty) return false;
  if (s.contains('pending')) return false;
  if (RegExp(r'\b(settled|completed|complete|done)\b').hasMatch(s)) {
    return true;
  }
  return s.contains('demat linked');
}

class _ReferralsListContent extends StatefulWidget {
  final List<ReferralListEntry> data;
  const _ReferralsListContent({required this.data});

  @override
  State<_ReferralsListContent> createState() => _ReferralsListContentState();
}

class _ReferralsListContentState extends State<_ReferralsListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'a-z';

  /// Matches [TopPerksScreen] tabs; maps to referral filters: 0 all, 1 pending, 2 settled.
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReferralListEntry> get _visibleEntries {
    var list = List<ReferralListEntry>.from(widget.data);
    switch (_tabIndex) {
      case 1:
        list = list.where(_referralLooksPending).toList();
        break;
      case 2:
        list = list.where(_referralLooksSettled).toList();
        break;
      default:
        break;
    }

    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      final qLower = q.toLowerCase();
      list = list.where((e) {
        final name = (e.name ?? '').toLowerCase();
        final status = (e.status ?? '').toLowerCase();
        if (name.contains(qLower)) return true;
        if (_tabIndex == 0) {
          if (qLower == 'settled') return _referralLooksSettled(e);
          if (qLower == 'pending') return _referralLooksPending(e);
        }
        return status.contains(qLower);
      }).toList();
    }
    list.sort((a, b) {
      final an = (a.name ?? '').toLowerCase();
      final bn = (b.name ?? '').toLowerCase();
      final c = an.compareTo(bn);
      return _sortBy == 'a-z' ? c : -c;
    });
    return list;
  }

  String _emptyCaption() {
    final q = _searchController.text.trim();
    if (q.isNotEmpty) return 'No matching referrals';
    switch (_tabIndex) {
      case 1:
        return 'No pending referrals';
      case 2:
        return 'No settled referrals yet';
      default:
        return 'No matching referrals';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEntries;
    return Column(
      spacing: 10,
      children: [
        CategorySearchSortBar(
          controller: _searchController,
          sortBy: _sortBy,
          onSearchChanged: (_) => setState(() {}),
          onToggleSort: () {
            setState(() {
              _sortBy = _sortBy == 'a-z' ? 'z-a' : 'a-z';
            });
          },
        ),
        TabButtons(
          selectedIndex: _tabIndex,
          onTap: (index) {
            setState(() => _tabIndex = index);
          },
          layoutWidthInset: 44,
          items: const ['All', 'Pending', 'Completed'],
        ),
        visible.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Center(
                  child: Text(
                    _emptyCaption(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SharePerksColors.textSecondaryLight,
                      fontFamily: SharePerksFonts.albertSans,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final entry = visible[i];
                  return ReferUser(
                    data: entry,
                    onTap: () => showInfoReferSteps(context, entry),
                  );
                },
              ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.REFER_CODE_SCREEN);
                },
                child: const Text("Refer and earn"),
              ),
              const ClickToHelp(),
            ],
          ),
        ),
      ],
    );
  }
}

class ReferUser extends StatelessWidget {
  final VoidCallback? onTap;
  final ReferralListEntry data;
  ReferUser({super.key, this.onTap, required this.data});
  final List<Color> _colors = [
    Color(0xFFFF4AA7),
    Color(0xFF5182FE),
    Color(0xFFD9D9D9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.all(0),
        leading: ImageBuilder(
          imageUrl: imageUrl(data.image ?? ""),
          width: 48,
          height: 48,
          borderRadius: 50,
        ),
        title: Text(
          data.name ?? "",
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 15,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          data.dateFormatted ?? "",
          style: TextStyle(
            color: const Color(0xFF898989),
            fontSize: 12,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 5,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: _colors[data.pendingStep ?? 0],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                data.status ?? "",
                style: TextStyle(
                  color: data.pendingStep == 2
                      ? const Color(0xFF333333)
                      : Colors.white,
                  fontSize: 10,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Text(
              data.pendingStep != 0
                  ? 'Only ${data.pendingStep} steps left!'
                  : "",
              style: TextStyle(
                color: const Color(0xFF333333),
                fontSize: 10,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w700,
                height: 1.40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showInfoReferSteps(BuildContext context, ReferralListEntry user) {
  final restoreScreen = trackBottomSheet('refer_steps_sheet');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return SizedBox(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.9,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const <double>[0.9, 1.0],
          builder: (ctx, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
                children: [
                  ReferUser(data: user),
                  const SizedBox(height: 20),
                  Text(
                    '3 user journey points:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.ASSETS_CARDS_REFERSTEPS_PNG,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.ASSETS_CARDS_REFERBANNERCARD_PNG,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  ).whenComplete(restoreScreen);
}
