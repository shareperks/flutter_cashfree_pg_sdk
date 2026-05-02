import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, state, child) {
        return Container(
          height: 94,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: const Color(0xFFFBFBFB),
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1.15, color: const Color(0xFFFF4AA7)),
              borderRadius: BorderRadius.circular(18.43),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 28.80,
                offset: Offset(0, 3.46),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              ImageBuilder(
                imageUrl: imageUrl(state.user?.image ?? ""),
                width: 60,
                height: 60,
                borderRadius: 100,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.user?.name ?? "",
                    style: TextStyle(
                      color: SharePerksColors.primary,
                      fontSize: 22,
                      fontFamily: SharePerksFonts.albertSans,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      context.pushNamed(RouteNames.PROFILE_EDIT_SCREEN);
                    },
                    child: Row(
                      spacing: 5,
                      children: [
                        Icon(
                          HugeIconsStroke.bubbleChatEdit,
                          color: SharePerksColors.textSecondaryLight,
                          size: 16,
                        ),
                        Text(
                          'View Profile Details',
                          style: TextStyle(
                            color: SharePerksColors.textSecondaryLight,
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                SharePerksColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
