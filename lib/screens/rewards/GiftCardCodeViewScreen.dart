import 'package:flutter/material.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/repository/models/my_claimed_giftcard_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:soui/elements/SpScafold.dart';

class GiftCardCodeViewScreen extends StatefulWidget {
  final String claimedId;
  const GiftCardCodeViewScreen({super.key, required this.claimedId});

  @override
  State<GiftCardCodeViewScreen> createState() => _GiftCardCodeViewScreenState();
}

class _GiftCardCodeViewScreenState extends State<GiftCardCodeViewScreen> {
  MyClaimedGiftcardDetailResponse? data;
  bool _loading = true;
  bool _isError = false;

  loadData() async {
    try {
      data = await RewardListingDataService.getMyClaimedGiftcardDetail(
        widget.claimedId,
      );
    } catch (e) {
      _isError = true;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Gift Card"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(children: [

        ],),
      ),
    );
  }
}
