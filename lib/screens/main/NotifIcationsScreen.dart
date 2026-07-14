import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/notification_model.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/services/notification/notification.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:soui/elements/tab_buttons.dart';

/// Notifications inbox.
///
/// - 5 category tabs (All / Perks / How to claim / Benefit / Referrals).
/// - Cursor-paginated feed with infinite scroll.
/// - Pull-to-refresh re-runs the current filter from scratch.
/// - Each row is a `Dismissible` for swipe-to-delete (`DELETE /:id`).
/// - App-bar action: "Mark all read" (`POST /mark-all-read`) — only enabled
///   when there's something unread.
/// - Tap on a row navigates via `screen` + `rewardId` (server may set them
///   to a `RouteNames.*` value with the reward id of the deep-link target).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _pageSize = 20;

  /// Tab labels paired with the server `category` enum string. Index 0 is
  /// "All" — no filter — so the user never has to hop tabs to see their
  /// full inbox. The remaining 4 mirror the server enum.
  static const List<({String label, String? category})> _tabs = [
    (label: 'All', category: null),
    (label: 'Perks', category: NotificationCategory.perks),
    (label: 'How to claim', category: NotificationCategory.howToClaim),
    (label: 'Benefit', category: NotificationCategory.benefit),
    (label: 'Referrals', category: NotificationCategory.referrals),
  ];

  /// Server screen names we know how to deep-link to. Anything else is
  /// surfaced as a non-tappable card so unknown server payloads don't crash.
  static const _knownRoutes = <String>{
    RouteNames.HOME_SCREEN,
    RouteNames.GIFTCARD_VIEW_SCREEN,
    RouteNames.CASHBACK_VIEW_SCREEN,
    RouteNames.PROMOCODE_VIEW_SCREEN,
    RouteNames.MY_WALLET_SCREEN,
    RouteNames.WALLET_HISTORY_SCREEN,
    RouteNames.EARNING_SCREEN,
    RouteNames.MY_REFER_LIST_SCREEN,
    RouteNames.REFER_CODE_SCREEN,
    RouteNames.CLAIMED_PERKS_SCREEN,
    RouteNames.MY_HOLDING_VIEW_SCREEN,
    RouteNames.PROFILE_EDIT_SCREEN,
    RouteNames.HELP_AND_SUPPORT_SCREEN,
    RouteNames.FAQS_SCREEN,
    RouteNames.SETTINGS_SCREEN,
  };

  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _markingAllRead = false;
  bool _clearingAll = false;
  bool _isError = false;

  List<AppNotification> _items = <AppNotification>[];
  String? _nextCursor;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    trackAction(AnalyticsEvent.notificationScreenViewed, {});
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Trigger when within ~400px of the bottom — enough lookahead that the
    // next page lands before the user notices.
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _isError = false;
      _items = const <AppNotification>[];
      _nextCursor = null;
    });
    try {
      final data = await NotificationService.list(
        limit: _pageSize,
        category: _tabs[_tabIndex].category,
      );
      if (!mounted) return;
      setState(() {
        _items = data.items;
        _nextCursor = data.nextCursor;
        _unreadCount = data.unreadCount;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final data = await NotificationService.list(
        limit: _pageSize,
        category: _tabs[_tabIndex].category,
      );
      if (!mounted) return;
      setState(() {
        _items = data.items;
        _nextCursor = data.nextCursor;
        _unreadCount = data.unreadCount;
        _isError = false;
      });
    } catch (_) {
      // Keep existing items on a transient failure; show a soft toast only
      // when we've got nothing to fall back to.
      if (!mounted) return;
      if (_items.isEmpty) setState(() => _isError = true);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading || _refreshing) return;
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final data = await NotificationService.list(
        limit: _pageSize,
        cursor: cursor,
        category: _tabs[_tabIndex].category,
      );
      if (!mounted) return;
      setState(() {
        _items = <AppNotification>[..._items, ...data.items];
        _nextCursor = data.nextCursor;
        _unreadCount = data.unreadCount;
      });
    } catch (_) {
      // Best-effort; pagination retries on next scroll trigger.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onTabSelected(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
    // Reset scroll position so the new (potentially shorter) list lands at
    // the top. `jumpTo` is safe even if the controller has no clients yet —
    // we guard with `hasClients` to avoid asserting during quick taps.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadInitial();
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead || _unreadCount == 0) return;
    setState(() => _markingAllRead = true);
    try {
      await NotificationService.markAllRead();
      if (!mounted) return;
      // Optimistic local flip — saves a round-trip and keeps the UI snappy.
      setState(() {
        _items = _items
            .map(
              (n) => AppNotification(
                id: n.id,
                title: n.title,
                description: n.description,
                image: n.image,
                type: n.type,
                category: n.category,
                isRead: true,
                screen: n.screen,
                rewardId: n.rewardId,
                createdAt: n.createdAt,
                createdAtFormatted: n.createdAtFormatted,
                timeFormatted: n.timeFormatted,
              ),
            )
            .toList();
        _unreadCount = 0;
      });
    } catch (_) {
      if (!mounted) return;
      _toast('Could not mark notifications as read.', error: true);
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  Future<void> _clearAll() async {
    if (_clearingAll || _items.isEmpty) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear all notifications'),
            content: const Text(
              'This will remove every notification from your inbox. '
              'You can\'t undo this.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEB3939),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;

    // Snapshot for rollback if the server rejects.
    final snapshotItems = _items;
    final snapshotUnread = _unreadCount;
    final snapshotCursor = _nextCursor;

    setState(() {
      _clearingAll = true;
      _items = const <AppNotification>[];
      _nextCursor = null;
      _unreadCount = 0;
    });
    try {
      await NotificationService.clearAll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = snapshotItems;
        _nextCursor = snapshotCursor;
        _unreadCount = snapshotUnread;
      });
      _toast('Could not clear notifications.', error: true);
    } finally {
      if (mounted) setState(() => _clearingAll = false);
    }
  }

  Future<bool> _confirmDelete(AppNotification n) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete notification'),
            content: const Text('Remove this notification from your inbox?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEB3939),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOne(AppNotification n) async {
    // Optimistic removal — restore on failure.
    final removedIndex = _items.indexWhere((e) => e.id == n.id);
    if (removedIndex < 0) return;
    setState(() {
      _items = List<AppNotification>.from(_items)..removeAt(removedIndex);
      if (!n.isRead && _unreadCount > 0) _unreadCount -= 1;
    });
    try {
      await NotificationService.deleteOne(n.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final restored = List<AppNotification>.from(_items)
          ..insert(removedIndex.clamp(0, _items.length), n);
        _items = restored;
        if (!n.isRead) _unreadCount += 1;
      });
      _toast('Could not delete the notification.', error: true);
    }
  }

  void _onNotificationTap(AppNotification n) {
    final screen = n.screen?.trim();
    if (screen == null || screen.isEmpty) return;
    if (!_knownRoutes.contains(screen)) return;

    final rewardId = n.rewardId;
    final extra = (rewardId != null && rewardId.isNotEmpty)
        ? <String, dynamic>{'rewardId': rewardId}
        : null;
    context.pushNamed(screen, extra: extra);
  }

  void _toast(String msg, {required bool error}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: error ? Colors.red : Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canMarkAll = _unreadCount > 0 && !_markingAllRead;
    final canClearAll = _items.isNotEmpty && !_clearingAll;
    final busy = _markingAllRead || _clearingAll;
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Notifications'),
        toolbarHeight: 40,
        actions: [
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<_NotificationMenuAction>(
              tooltip: 'Notification options',
              icon: const Icon(Icons.more_vert, color: Color(0xFF333333)),
              onSelected: (action) {
                switch (action) {
                  case _NotificationMenuAction.markAllRead:
                    _markAllRead();
                  case _NotificationMenuAction.clearAll:
                    _clearAll();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<_NotificationMenuAction>(
                  enabled: canMarkAll,
                  value: _NotificationMenuAction.markAllRead,
                  child: const Text('Mark all read'),
                ),
                PopupMenuItem<_NotificationMenuAction>(
                  enabled: canClearAll,
                  value: _NotificationMenuAction.clearAll,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: canClearAll
                          ? const Color(0xFFEB3939)
                          : const Color(0xFFB0B0B0),
                    ),
                  ),
                ),
              ],
            ),
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                // `layoutWidthInset` must cover both the outer Padding
                // (18 + 18 = 36) and `TabButtons`'s own outer-container
                // margins (2 + 4 = 6 of `outerContainerMargin: 4`, totaling
                // 24 px). Without the extra 24 the inner `Row` overflows
                // by 8 px on tighter screens — see
                // soui/lib/elements/tab_buttons.dart `outerW` formula.
                child: TabButtons(
                  selectedIndex: _tabIndex,
                  layoutWidthInset: 60,
                  buttonTextFontSize: 11,
                  items: <String>[for (final t in _tabs) t.label],
                  onTap: _onTabSelected,
                ),
              ),
            ),
            ..._buildBodySlivers(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_initialLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }

    if (_isError && _items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(onRetry: _loadInitial),
        ),
      ];
    }

    if (_items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverList.builder(
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              if (_nextCursor == null || _nextCursor!.isEmpty) {
                return const SizedBox(height: 20);
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final n = _items[index];
            return Dismissible(
              key: ValueKey<String>(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB3939),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (_) => _confirmDelete(n),
              onDismissed: (_) => _deleteOne(n),
              child: _NotificationCard(
                notification: n,
                onTap: _knownRoutes.contains(n.screen)
                    ? () => _onNotificationTap(n)
                    : null,
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final hasImage = n.image.trim().isNotEmpty;
    final timestamp = n.displayTimestamp;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isRead
              ? Colors.white
              : SharePerksColors.primary.withAlpha(14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead
                ? const Color(0xFFEFEFEF)
                : SharePerksColors.primary.withAlpha(40),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: hasImage
                  ? ImageBuilder(
                      imageUrl: imageUrl(n.image),
                      width: 44,
                      height: 44,
                      borderRadius: 8,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: SharePerksColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        HugeIconsSolid.notification01,
                        color: SharePerksColors.primary,
                        size: 22,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: SharePerksColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (n.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      n.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF6B6B6B),
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (timestamp.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: const Color(0xFF898989),
                        fontSize: 10,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIconsSolid.notification01,
            size: 56,
            color: SharePerksColors.primary.withAlpha(80),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up",
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 15,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New activity will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF898989),
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

enum _NotificationMenuAction { markAllRead, clearAll }

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 14,
              fontFamily: SharePerksFonts.albertSans,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
