import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/bottom_navigation.dart';
import 'package:soui/theme.dart';

class BottomNavigationBarComponent extends StatelessWidget {
  const BottomNavigationBarComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomBottomNavigationBar(
        backgroundColor: Colors.transparent,
        iconSize: 28,
        labelStyle: TextStyle(fontSize: 8),
        selectedLabelStyle: TextStyle(fontSize: 8, color: AppColors.brand),
        selectedIndex: 0,
        height: 70,
        trailingSize: 70,
        padding: EdgeInsets.symmetric(horizontal: 18.0),
        barPadding: EdgeInsets.symmetric(horizontal: 10.0),
        itemSpacing: 10.0,
        itemMainAxisAlignment: MainAxisAlignment.spaceBetween,
        trailingColor: AppColors.white,
        borderRadius: 18,
        trailingBoxShadow: [
          BoxShadow(
            color: AppColors.neutral200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        items: [
          CustomBottomNavigationItem(
            icon: HugeIconsSolid.home09,
            activeIconColor: AppColors.brand,
            label: 'Home',
          ),
          CustomBottomNavigationItem(
            icon: HugeIconsSolid.starCircle,
            label: 'Rewards',
          ),

          CustomBottomNavigationItem(
            icon: HugeIconsSolid.chart01,
            label: 'Holding',
            onTap: () {
              context.pushNamed(RouteNames.MY_HOLDING_VIEW_SCREEN);
            },
          ),
          CustomBottomNavigationItem(
            icon: HugeIconsSolid.wallet01,
            label: 'Wallet',
          ),
        ],
        trailing: GestureDetector(
          onTap: () {
            context.pushNamed(RouteNames.MENU_SCREEN);
          },
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Consumer<UserProvider>(
              builder: (context, state, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: ImageBuilder(
                    imageUrl: imageUrl(state.user?.image ?? ""),
                    fit: BoxFit.cover,
                    width: 25,
                    height: 25,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
