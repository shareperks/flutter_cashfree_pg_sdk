import 'package:flutter/material.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/ImageBuilder.dart';

class CategoryView extends StatelessWidget {
  final String title;
  final String image;
  const CategoryView({super.key, this.title = "", this.image = ""});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 5,
        children: [
          ImageBuilder(imageUrl: image, width: 75, height: 75),
          Text(
            '$title',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SharePerksColors.surfaceDark,
              fontSize: 12,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryViewTab extends StatelessWidget {
  final bool isActive;
  const CategoryViewTab({super.key, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          width: isActive ? 1 : 0,
          color: isActive ? SharePerksColors.inputBorderLight : Colors.white,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CategoryView(),
    );
  }
}
