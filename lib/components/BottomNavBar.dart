import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
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
            label: 'History',
          ),
          CustomBottomNavigationItem(
            icon: HugeIconsSolid.wallet01,
            label: 'Wallet',
          ),
        ],
        trailing: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.network(
              "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?fm=jpg&q=60&w=3000&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dXNlcnxlbnwwfHwwfHx8MA%3D%3D",
              fit: BoxFit.cover,
              width: 25,
              height: 25,
            ),
          ),
        ),
      ),
    );
  }
}
