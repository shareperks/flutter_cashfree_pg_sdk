import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/components/loader/NotificationListShimmer.dart';
import 'package:shareperks/components/notification/NotificationCard.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/notification_model.dart';
import 'package:shareperks/integrations/analytics/analytics_event.dart';
import 'package:shareperks/integrations/analytics/tracked_action.dart';
import 'package:shareperks/repository/services/notification/notification.service.dart';
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
    RouteNames.UNLOCKED_PERKS_SCREEN,
    RouteNames.GIFTCARD_PERK_SCREEN,
    RouteNames.PROMOOCODE_PERK_SCREEN,
    RouteNames.CASHBACK_PERK_SCREEN,
    RouteNames.TOP_PERKS_SCREEN,
    RouteNames.TOP_BRANDS_SCREEN,
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
      backgroundColor: SharePerksColors.surfaceLight,
      appBar: AppBar(
        leading: AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0 && !_initialLoading)
              Text(
                '$_unreadCount unread',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 11,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        toolbarHeight: _unreadCount > 0 && !_initialLoading ? 48 : 40,
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
              icon: const Icon(Icons.more_vert, color: Colors.white),
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
          const SizedBox(width: 8),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TabButtons(
                  selectedIndex: _tabIndex,
                  layoutWidthInset: 56,
                  buttonTextFontSize: 11,
                  items: <String>[for (final t in _tabs) t.label],
                  onTap: _onTabSelected,
                ),
              ),
            ),
            if (_unreadCount > 0 && !_initialLoading && !_isError)
              SliverToBoxAdapter(
                child: _UnreadBanner(
                  unreadCount: _unreadCount,
                  markingAllRead: _markingAllRead,
                  onMarkAllRead: _markAllRead,
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
      return const [NotificationListShimmer()];
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
        SliverFillRemaining(hasScrollBody: false, child: _EmptyState()),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        sliver: SliverList.builder(
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              if (_nextCursor == null || _nextCursor!.isEmpty) {
                return const SizedBox(height: 8);
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final n = _items[index];
            final isActionable =
                n.screen != null &&
                n.screen!.trim().isNotEmpty &&
                _knownRoutes.contains(n.screen);
            return Dismissible(
              key: ValueKey<String>(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: SharePerksColors.error,
                  borderRadius: BorderRadius.circular(SharePerksRadii.lg),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) => _deleteOne(n),
              child: NotificationCard(
                notification: n,
                isActionable: isActionable,
                onTap: isActionable ? () => _onNotificationTap(n) : null,
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _UnreadBanner extends StatelessWidget {
  const _UnreadBanner({
    required this.unreadCount,
    required this.markingAllRead,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool markingAllRead;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SharePerksColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
          border: Border.all(
            color: SharePerksColors.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SharePerksColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                HugeIconsSolid.notification01,
                size: 18,
                color: SharePerksColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                unreadCount == 1
                    ? 'You have 1 unread notification'
                    : 'You have $unreadCount unread notifications',
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (markingAllRead)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: onMarkAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: SharePerksColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Mark all read'),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SharePerksRadii.lg),
            border: Border.all(color: SharePerksColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SharePerksColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  HugeIconsSolid.notification01,
                  size: 30,
                  color: SharePerksColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "You're all caught up",
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 16,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'New perks, benefits, and updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SharePerksRadii.lg),
            border: Border.all(color: SharePerksColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                HugeIconsSolid.alertCircle,
                size: 40,
                color: SharePerksColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 15,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 13,
                  fontFamily: SharePerksFonts.inter,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
