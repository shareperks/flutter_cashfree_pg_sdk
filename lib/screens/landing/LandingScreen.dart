import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    trackAction(AnalyticsEvent.landingViewed, {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage(Assets.ASSETS_LANDING_PNG),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 8,
            children: [
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.goNamed(RouteNames.LOGIN_SCREEN);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SharePerksColors.accent,
                ),
                child: Text("Get Started"),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Investing deserves ',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 22,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: 'recognition',
                      style: TextStyle(
                        color: SharePerksColors.accent,
                        fontSize: 22,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Shareperks recognises long-term investors with meaningful benefits & rewards.',
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
