import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/notification_model.dart';

/// Category styling for notification inbox rows.
class NotificationCategoryStyle {
  const NotificationCategoryStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static NotificationCategoryStyle forCategory(String category) {
    switch (category.toUpperCase()) {
      case 'PERKS':
        return NotificationCategoryStyle(
          label: 'Perks',
          color: SharePerksColors.primary,
          icon: HugeIconsSolid.giftCard,
        );
      case 'HOW_TO_CLAIM':
        return NotificationCategoryStyle(
          label: 'How to claim',
          color: SharePerksColors.info,
          icon: HugeIconsSolid.helpCircle,
        );
      case 'BENEFIT':
        return NotificationCategoryStyle(
          label: 'Benefit',
          color: SharePerksColors.success,
          icon: HugeIconsSolid.wallet01,
        );
      case 'REFERRALS':
        return NotificationCategoryStyle(
          label: 'Referrals',
          color: SharePerksColors.secondary,
          icon: HugeIconsSolid.userGroup,
        );
      default:
        return NotificationCategoryStyle(
          label: 'Update',
          color: SharePerksColors.textSecondaryLight,
          icon: HugeIconsSolid.notification01,
        );
    }
  }
}

/// Single notification row for the inbox list.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.isActionable = false,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final bool isActionable;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final timestamp = n.displayTimestamp;
    final category = NotificationCategoryStyle.forCategory(n.category);
    final isUnread = !n.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isUnread
                ? SharePerksColors.primary.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(SharePerksRadii.lg),
            boxShadow: isUnread ? SharePerksShadows.sm : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SharePerksRadii.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isUnread)
                    Container(
                      width: 4,
                      color: SharePerksColors.primary,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _CategoryChip(style: category),
                                    const Spacer(),
                                    if (isUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: SharePerksColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  n.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: SharePerksColors.textPrimaryLight,
                                    fontSize: 14,
                                    fontFamily: SharePerksFonts.albertSans,
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                if (n.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    n.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: SharePerksColors.textSecondaryLight,
                                      fontSize: 12,
                                      fontFamily: SharePerksFonts.inter,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (timestamp.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        HugeIconsSolid.clock01,
                                        size: 12,
                                        color: SharePerksColors.textSecondaryLight
                                            .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          timestamp,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: SharePerksColors
                                                .textSecondaryLight,
                                            fontSize: 11,
                                            fontFamily: SharePerksFonts.inter,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isActionable) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                HugeIconsSolid.arrowRight01,
                                size: 16,
                                color: SharePerksColors.primary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.style});

  final NotificationCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 10,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
