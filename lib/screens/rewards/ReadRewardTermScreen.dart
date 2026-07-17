import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/repository/models/reward_content_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:soui/elements/SpScafold.dart';

class ReadRewardTermScreen extends StatefulWidget {
  final String contentId;
  const ReadRewardTermScreen({super.key, required this.contentId});

  @override
  State<ReadRewardTermScreen> createState() => _ReadRewardTermScreenState();
}

class _ReadRewardTermScreenState extends State<ReadRewardTermScreen> {
  RewardContent? _data;
  bool _loading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final c = await RewardListingDataService.getRewardContent(
        widget.contentId,
      );
      if (!mounted) return;
      setState(() {
        _data = c;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _loadError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Terms & Conditions"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
        toolbarHeight: 40,
      ),
      body: _buildBody(_data?.termsAndConditionsFull ?? ""),
    );
  }

  Widget _buildBody(String html) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load terms. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: 16,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: HtmlWidget(
        html,
        textStyle: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
