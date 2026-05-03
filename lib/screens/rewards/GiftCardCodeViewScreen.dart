import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/loader/GiftCardCodeViewShimmer.dart';
import 'package:shareperks/components/PerkBasicInfo.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/my_claimed_giftcard_detail_model.dart';
import 'package:shareperks/repository/services/listing/rewards.service.dart';
import 'package:shareperks/screens/refer/ReferAndEarnCodeScreen.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/border_card.dart';
import 'package:soui/elements/key_value_list.dart';

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
  QrImage? _qrImage;

  Future<void> loadData() async {
    try {
      data = await RewardListingDataService.getMyClaimedGiftcardDetail(
        widget.claimedId,
      );
      final qrCode = QrCode(8, QrErrorCorrectLevel.H)
        ..addData(data?.data?.card?.code ?? "");
      _qrImage = QrImage(qrCode);
      _isError = false;
    } catch (e) {
      _isError = true;
      _qrImage = null;
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
    final card = data?.data?.card;
    final codeText = (card?.code ?? '').trim();
    final pinText = (card?.pin ?? '').trim();

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
      body: _loading
          ? const GiftCardCodeViewShimmer()
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    spacing: 20,
                    children: [
                      BorderCard(
                        width: MediaQuery.of(context).size.width,
                        color: SharePerksColors.primary.withAlpha(50),
                        padding: EdgeInsets.all(10),
                        borderRadius: 16,
                        child: Column(
                          spacing: 10,
                          children: [
                            ImageBuilder(
                              imageUrl: imageUrl(
                                data?.data?.info?.banner ?? "",
                              ),
                              width: MediaQuery.of(context).size.width,
                              borderRadius: 14,
                              alignment: Alignment.bottomLeft,
                              aspectRatio: 2.65,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                spacing: 10,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PerkInfoBar(type: "CREDIT"),
                                  Text(
                                    data?.data?.info?.name ?? "",
                                    style: TextStyle(
                                      color: const Color(0xFF333333),
                                      fontSize: 20,
                                      fontFamily: SharePerksFonts.albertSans,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  KeyValueList(
                                    keyWidth: 90,
                                    keyWidget: Text(
                                      "Brand Name",
                                      style: TextStyle(
                                        color: const Color(0xFF898989),
                                        fontSize: 12,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    valueWidget: InkWell(
                                      onTap: () {
                                        context.pushNamed(
                                          RouteNames.BRAND_SCREEN,
                                          extra: {
                                            "brandId":
                                                data?.data?.info?.brandId,
                                          },
                                        );
                                      },
                                      child: Text(
                                        data?.data?.info?.brandName ?? "--",
                                        style: TextStyle(
                                          color: const Color(
                                            0xFF5182FE,
                                          ) /* Information */,
                                          fontSize: 12,
                                          fontFamily: SharePerksFonts.inter,
                                          fontWeight: FontWeight.w400,

                                          decorationColor: const Color(
                                            0xFF5182FE,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  KeyValueList(
                                    keyWidth: 90,
                                    keyWidget: Text(
                                      "Balance",
                                      style: TextStyle(
                                        color: const Color(0xFF898989),
                                        fontSize: 12,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    valueWidget: Text(
                                      "₹ ${data?.data?.card?.rewardAmount?.toStringAsFixed(2) ?? "0.00"}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  KeyValueList(
                                    keyWidth: 90,
                                    keyWidget: Text(
                                      "Expiry Date",
                                      style: TextStyle(
                                        color: const Color(0xFF898989),
                                        fontSize: 12,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    valueWidget: Text(
                                      "${data?.data?.card?.expireAtFormatted}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: SharePerksFonts.inter,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            radius: const Radius.circular(5),
                            dashPattern: const [10, 5],
                            strokeWidth: 1,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            strokeCap: StrokeCap.round,
                            color: SharePerksColors.borderLight,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Voucher code',
                                        style: TextStyle(
                                          color: SharePerksColors.primary,
                                          fontSize: 12,
                                          fontFamily:
                                              SharePerksFonts.albertSans,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          barrierColor: Colors.white,
                                          builder: (context) {
                                            return AlertDialog(
                                              elevation: 0,
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                spacing: 12,
                                                children: [
                                                  SvgPicture.asset(
                                                    Assets.ASSETS_LOGO_SVG,
                                                  ),
                                                  Text(
                                                    'Scan qr code ₹ ${data?.data?.card?.rewardAmount?.toStringAsFixed(2)} share gift card',
                                                    style: TextStyle(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.50,
                                                          ),
                                                      fontSize: 8.22,
                                                      fontFamily:
                                                          SharePerksFonts.inter,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  if (_qrImage != null)
                                                    PrettyQrView(
                                                      qrImage: _qrImage!,
                                                      decoration: const PrettyQrDecoration(
                                                        image: PrettyQrDecorationImage(
                                                          clipper:
                                                              PrettyQrCircleClipper(),
                                                          image: AssetImage(
                                                            Assets
                                                                .ASSETS_ICONS_APP_LOGO_PNG,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Text(
                                                    'PIN: ${data?.data?.card?.pin}',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF6400E0,
                                                      ),
                                                      fontSize: 14,
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.57,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Share Gift Card",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(
                                        HugeIconsSolid.qrCode,
                                        size: 18,
                                        color: codeText.isEmpty
                                            ? SharePerksColors
                                                  .textSecondaryLight
                                            : SharePerksColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  codeText.isNotEmpty ? codeText : '—',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: codeText.isNotEmpty
                                        ? SharePerksColors.primary
                                        : SharePerksColors.textSecondaryLight,
                                    fontSize: 26,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: codeText.isNotEmpty
                                        ? 1.4
                                        : 0,
                                    height: 1.2,
                                  ),
                                ),
                                if (pinText.isNotEmpty) ...[
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Security PIN',
                                          style: TextStyle(
                                            color: SharePerksColors
                                                .textSecondaryLight,
                                            fontSize: 12,
                                            fontFamily: SharePerksFonts.inter,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    pinText,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: SharePerksColors.textPrimaryLight,
                                      fontSize: 16,
                                      fontFamily: SharePerksFonts.albertSans,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (data?.data?.isUsedByUser == false)
                        GestureDetector(
                          child: Text(
                            'Mark as redeemed',
                            style: TextStyle(
                              color: const Color(0xFF6400E0),
                              fontSize: 14,
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Column(
                        spacing: 20,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.pushNamed(
                                RouteNames.HELP_AND_SUPPORT_SCREEN,
                              );
                            },
                            child: Image.asset(
                              Assets.ASSETS_CARDS_SUPPORTCARD_PNG,
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                          ReferCodeCard(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: !_loading
          ? FloatingActionButton(
              elevation: 0,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(50),
              ),
              onPressed: () {},
              child: Icon(HugeIconsSolid.share08),
            )
          : null,
    );
  }
}
