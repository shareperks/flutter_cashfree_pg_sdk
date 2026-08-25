import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/ClickToHelp.dart';
import 'package:shareperks/components/FaqItem.dart';
import 'package:shareperks/components/loader/FaqListShimmer.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/repository/models/information_faq_model.dart';
import 'package:shareperks/repository/services/listing/informations.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  static const List<String> _tabs = [
    "Perks",
    "How to claim",
    "Benefit",
    "Referrals",
  ];

  final TextEditingController _searchController = TextEditingController();

  InformationFaqListResponse? _data;
  bool _loading = true;
  bool _isError = false;
  int _tabIndex = 0;
  String _searchQuery = '';

  List<InformationFaq> get _filteredItems {
    final items = _data?.items ?? <InformationFaq>[];
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<InformationFaq>.from(items);
    return items.where((e) {
      final qu = (e.question ?? '').toLowerCase();
      final an = (e.answer ?? '').toLowerCase();
      return qu.contains(q) || an.contains(q);
    }).toList();
  }

  Future<void> _loadData(int index) async {
    setState(() {
      _tabIndex = index;
      _loading = true;
      _isError = false;
    });
    try {
      final result = await InformationsService.fetchFaqs(type: _tabs[index]);
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _data = null;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadData(_tabIndex);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("FAQs"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData(_tabIndex);
        },
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(18),
            width: MediaQuery.of(context).size.width,
            child: Column(
              spacing: 10,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(HugeIconsSolid.search01),
                    hintText: "Search for help...",
                  ),
                ),
                TabButtons(
                  key: ValueKey<int>(_tabIndex),
                  layoutWidthInset: 44,
                  items: _tabs,
                  initialSelectedIndex: _tabIndex,
                  onTap: (index) {
                    _loadData(index);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: _buildFaqList(),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    context.pushNamed(RouteNames.HOW_SHOW_PERK_SCREEN);

                    // TODO: Navigate to show we show perks screen
                  },
                  child: Image.asset(
                    Assets.ASSETS_CARDS_SHOW_WE_SHOW_PERKS_PNG,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
                SizedBox(height: 10),
                ClickToHelp(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 16),
        child: FaqListShimmer(itemCount: 6),
      );
    }
    if (_isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          spacing: 12,
          children: [
            Text(
              'Could not load FAQs. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF898989),
                fontSize: 14,
                fontFamily: SharePerksFonts.albertSans,
              ),
            ),
            TextButton(
              onPressed: () => _loadData(_tabIndex),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          _searchQuery.trim().isEmpty
              ? 'No questions in this section yet.'
              : 'No results for your search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF898989),
            fontSize: 14,
            fontFamily: SharePerksFonts.albertSans,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          FaqItem(
            showBorder: true,
            question: items[i].question ?? '',
            answer: items[i].answer ?? '',
          ),
      ],
    );
  }
}
