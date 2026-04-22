import 'package:flutter/material.dart';
import 'package:shareperks/constants/theme_data.dart';

class Copyright extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  const Copyright({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Investing Made ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: SharePerksColors.borderDark,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Rewarding',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: SharePerksColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© All rights reserved by Shareperks Technologies Pvt. Ltd.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
