import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/holdings.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/integrations/smallcase_gateway.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/icon.dart';
import 'package:soui/theme.dart';

class ListBrokerScreen extends StatefulWidget {
  const ListBrokerScreen({super.key});

  @override
  State<ListBrokerScreen> createState() => _ListBrokerScreenState();
}

class _ListBrokerScreenState extends State<ListBrokerScreen> {
  @override
  void initState() {
    super.initState();
    trackAction(AnalyticsEvent.brokerListViewed, {});
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Select Broker"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16).copyWith(top: 40),
        child: GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          children: List.generate(HoldingsBrokerAssets.all.length, (index) {
            HoldingBroker broker = HoldingsBrokerAssets.all[index];
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                GestureDetector(
                  onTap: () async {
                    trackAction(AnalyticsEvent.brokerSelected, {
                      'broker_id': broker.brokerKey,
                    });
                    if (broker.supportsSmallcase) {
                      await SmallcaseGateway.importHolding(
                        broker,
                        (status) {
                          if (status) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  content: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      spacing: 10,
                                      children: [
                                        SizedBox(height: 20),
                                        SouiIcon.logo(
                                          color: AppColors.white,
                                          size: 75,
                                        ),
                                        SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            context.pop();
                          }
                        },
                        (complete) {
                          Timer(Duration(seconds: 1), () {
                            context.pushNamed(
                              RouteNames.MY_HOLDING_VIEW_SCREEN,
                            );
                          });
                        },
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: SharePerksColors.borderLight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(100),
                      child: Image.asset(
                        broker.imageAssetPath,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                ),
                Text(broker.name, style: TextStyle(fontSize: 8)),
              ],
            );
          }),
        ),
      ),

      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 80,
        color: Colors.white,
        child: Center(
          child: Column(
            spacing: 10,
            children: [
              Text(
                'Or upload a statement',
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: 10,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 40,
                child: OutlinedButton(
                  onPressed: () {
                    context.pushNamed(RouteNames.UPLOAD_HOLDING_SCREEN);
                  },
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(HugeIconsSolid.fileUpload),
                      Text("Upload consolidated statement"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
