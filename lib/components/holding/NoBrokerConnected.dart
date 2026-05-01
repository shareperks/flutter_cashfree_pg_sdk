import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';

class NoBrokerConnected extends StatelessWidget {
  const NoBrokerConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'No broker connected yet',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: SharePerksColors.textPrimaryLight,
            fontSize: 20,
            fontFamily: SharePerksFonts.albertSans,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your broker to import holdings, track your portfolio, and place orders seamlessly.',
          style: TextStyle(
            color: SharePerksColors.textSecondaryLight,
            fontSize: 14,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        _FeatureBullet(
          title: '1. Import holdings',
          subtitle: 'Connect your broker to securely import your holdings.',
        ),
        const SizedBox(height: 10),
        _FeatureBullet(
          title: '2. Check your eligibility',
          subtitle:
              'We’ll calculate your eligibility based on your imported holdings.',
        ),
        const SizedBox(height: 10),
        _FeatureBullet(
          title: '3. Unlock extra rewards',
          subtitle: 'Get access to additional perks and rewards instantly.',
        ),
        const SizedBox(height: 22),
        Spacer(),
        ElevatedButton(
          onPressed: () {
            context.pushNamed(RouteNames.LIST_BROKER_VIEW_SCREEN);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            "Connect Broker",
            style: TextStyle(
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: SharePerksColors.borderLight),
          ),
          child: Text(
            "Not now",
            style: TextStyle(
              color: SharePerksColors.textPrimaryLight,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 22,
          width: 22,
          decoration: BoxDecoration(
            color: SharePerksColors.borderLight.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: SharePerksColors.textSecondaryLight,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 14,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
