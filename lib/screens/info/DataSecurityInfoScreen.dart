import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';

/// Explains how SharePerks protects user data with AES-256 encryption.
class DataSecurityInfoScreen extends StatelessWidget {
  const DataSecurityInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Data security'),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 16),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroCard(),
            const SizedBox(height: 20),
            _SectionTitle('How we protect your data'),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.primary,
              icon: HugeIconsSolid.databaseLocked,
              title: 'AES-256 encryption at rest',
              body:
                  'Sensitive information — your holdings, PAN, broker details and payout data — is encrypted with AES-256 before it is written to our database. Even if storage media were accessed directly, the contents stay unreadable without the keys.',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.info,
              icon: HugeIconsSolid.shield01,
              title: 'Encrypted in transit (TLS)',
              body:
                  'Every request between the app and our servers travels over HTTPS with TLS 1.2 or higher. Nothing is sent over plain HTTP, so your data cannot be read on public or shared networks.',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.accent,
              icon: HugeIconsSolid.key01,
              title: 'Keys stored separately',
              body:
                  'Encryption keys never live alongside the encrypted data. They are held in a managed key store with restricted access and are rotated periodically, so a single breach point is not enough to decrypt anything.',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.success,
              icon: HugeIconsSolid.eye,
              title: 'Read-only broker access',
              body:
                  'We only read your holdings to check perk eligibility. SharePerks can never place trades, move funds, or change anything in your demat account, and we do not store your broker password.',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.primary,
              icon: HugeIconsSolid.fingerPrint,
              title: 'Account protection',
              body:
                  'Sign-in uses OTP verification, and you can turn on multi-factor authentication for an extra layer. Sessions are token-based and can be revoked at any time.',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              accent: SharePerksColors.textSecondaryLight,
              icon: HugeIconsSolid.securityLock,
              title: 'Minimum data, on request deletion',
              body:
                  'We collect only what is needed to unlock and deliver perks. Statements are processed to extract holdings and are not shared with brands. You can ask us to delete your data at any time.',
            ),
            const SizedBox(height: 20),
            _SectionTitle('What AES-256 means'),
            const SizedBox(height: 8),
            Text(
              'AES-256 is the Advanced Encryption Standard with a 256-bit key — the same class of encryption used by banks and governments to protect confidential data. Guessing a 256-bit key by brute force is not practical with current computing power.',
              style: TextStyle(
                color: SharePerksColors.textSecondaryLight,
                fontSize: 13,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SharePerksColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'We will never ask for your broker password, OTP, or card PIN over call, email, or chat. If someone does, it is not SharePerks.',
                style: TextStyle(
                  color: SharePerksColors.primary,
                  fontSize: 12,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.pushNamed(RouteNames.HELP_AND_SUPPORT_SCREEN);
                },
                icon: Icon(
                  HugeIconsSolid.shieldUser,
                  size: 18,
                  color: SharePerksColors.primary,
                ),
                label: Text(
                  'Questions about your data?',
                  style: TextStyle(
                    color: SharePerksColors.primary,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: SharePerksColors.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: SharePerksColors.primary.withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SharePerksColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SharePerksColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SharePerksColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              HugeIconsSolid.shieldKey,
              size: 26,
              color: SharePerksColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your data stays secure',
            style: TextStyle(
              color: SharePerksColors.textPrimaryLight,
              fontSize: 22,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use AES-256 encryption to keep your holdings and personal details private. At SharePerks, your privacy is our priority.',
            style: TextStyle(
              color: SharePerksColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: SharePerksColors.textPrimaryLight,
        fontSize: 16,
        fontFamily: SharePerksFonts.albertSans,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SharePerksColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 15,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: SharePerksColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
