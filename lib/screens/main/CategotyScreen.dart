import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/CategoryView.dart';
import 'package:shareperks/components/NotFoundView.dart';
import 'package:shareperks/components/RewardCard.dart';
import 'package:shareperks/components/loader/rewardloader.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';
import 'package:soui/theme.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        title: Text('Unlocked Perks'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
        centerTitle: false,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          SizedBox(width: 20),
        ],
      ),

      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            child: Column(
              spacing: 18.0,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          CategoryViewTab(isActive: true),
                          CategoryViewTab(),
                        ],
                      ),
                      SizedBox(height: 12),

                      Row(
                        spacing: 5,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 88,
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(HugeIconsSolid.search01),
                                hintText: "Unlocked Perks",
                              ),
                            ),
                          ),

                          Container(
                            alignment: Alignment.center,
                            width: 44,
                            child: Center(
                              child: Icon(
                                HugeIconsSolid.arrowUpDown,
                                color: AppColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          runAlignment: WrapAlignment.start,
                          alignment: WrapAlignment.start,
                          children: [
                            NotFoundView(),
                            RewardLoader(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                            ),
                            RewardCard(
                              rewardId: '123',
                              type: 'OFFER',
                              typeName: 'CREDIT',
                              title: 'Coupon Title on the given brand',
                              imageUrl:
                                  'https://assets.aboutamazon.com/dims4/default/bd89a42/2147483647/strip/false/crop/1280x720+0+0/resize/1280x720!/quality/90/?url=https%3A%2F%2Famazon-blogs-brightspot.s3.amazonaws.com%2F77%2F09%2Fcd428ca04437b8ecf6e172e2233f%2Fweb-banner.jpg',
                              isEligible: true,
                              eligibility: "Eternal",
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                            ),
                            RewardCard(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                              rewardId: '123',
                              type: 'OFFER',
                              typeName: 'CREDIT',
                              title: 'Coupon Title on the given brand',
                              imageUrl:
                                  'https://assets.aboutamazon.com/dims4/default/bd89a42/2147483647/strip/false/crop/1280x720+0+0/resize/1280x720!/quality/90/?url=https%3A%2F%2Famazon-blogs-brightspot.s3.amazonaws.com%2F77%2F09%2Fcd428ca04437b8ecf6e172e2233f%2Fweb-banner.jpg',
                              isEligible: false,
                              isNew: true,
                              eligibility: "Eternal",
                            ),
                            RewardCard(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                              rewardId: '123',
                              type: 'OFFER',
                              typeName: 'CREDIT',
                              title: 'Coupon Title on the given brand',
                              imageUrl:
                                  'https://assets.aboutamazon.com/dims4/default/bd89a42/2147483647/strip/false/crop/1280x720+0+0/resize/1280x720!/quality/90/?url=https%3A%2F%2Famazon-blogs-brightspot.s3.amazonaws.com%2F77%2F09%2Fcd428ca04437b8ecf6e172e2233f%2Fweb-banner.jpg',
                              isEligible: false,
                              isNew: true,
                              eligibility: "Eternal",
                            ),
                            RewardCard(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                              rewardId: '123',
                              type: 'OFFER',
                              typeName: 'CREDIT',
                              title: 'Coupon Title on the given brand',
                              imageUrl:
                                  'https://assets.aboutamazon.com/dims4/default/bd89a42/2147483647/strip/false/crop/1280x720+0+0/resize/1280x720!/quality/90/?url=https%3A%2F%2Famazon-blogs-brightspot.s3.amazonaws.com%2F77%2F09%2Fcd428ca04437b8ecf6e172e2233f%2Fweb-banner.jpg',
                              isEligible: false,
                              isNew: true,
                              eligibility: "Eternal",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
