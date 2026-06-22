import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics_event.dart';
import 'analytics_sink.dart';

/// Posts events to the SharePerks data_service `/track/batch` endpoint with
/// an offline-tolerant queue. Guarantees the doc requirement: "a missing /
/// broken SDK must never crash the app" — every public method is wrapped in
/// try/catch and either swallows the error or drops the event.
///
/// Flush triggers (any of):
///   * queue length reaches [_flushThreshold]
///   * 15s periodic timer while the app is foregrounded
///   * `app_backgrounded` (via [flush] called from `AnalyticsService`)
///   * connectivity comes back online
///
/// Retry strategy on network / 5xx: exponential backoff
///   2s, 5s, 15s, 60s, 120s, 300s (cap)
/// On 400: drop the event (schema bug, will keep failing) + log
/// On 429: wait 30s before next attempt, do not drop
class ServerSink implements AnalyticsSink {
  ServerSink({
    required this.baseUrl,
    required this.getAuthToken,
    Dio? dio,
    int flushThreshold = 20,
    Duration periodicFlush = const Duration(seconds: 15),
    int queueCap = 500,
    int batchSize = 50,
  })  : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8))),
        _flushThreshold = flushThreshold,
        _periodicFlush = periodicFlush,
        _queueCap = queueCap,
        _batchSize = batchSize;

  /// Tracking API origin (no trailing slash), e.g. `https://listing.shareperks.in`.
  final String baseUrl;

  /// Returns the current JWT or null if the user is logged out. Read on every
  /// flush so a fresh post-login token starts being attached automatically.
  final Future<String?> Function() getAuthToken;

  final Dio _dio;
  final int _flushThreshold;
  final Duration _periodicFlush;
  final int _queueCap;
  final int _batchSize;

  static const _persistKey = 'analytics_server_queue_v1';

  final Queue<Map<String, Object?>> _queue = Queue<Map<String, Object?>>();
  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _flushing = false;
  DateTime? _backoffUntil;
  Duration _nextBackoff = const Duration(seconds: 2);
  String? _anonIdHeader;

  @override
  String get name => 'server';

  @override
  Future<void> init() async {
    try {
      await _restorePersistedQueue();
      _periodicTimer = Timer.periodic(_periodicFlush, (_) => _safeFlush());
      _connSub = Connectivity().onConnectivityChanged.listen((results) {
        final hasNet = results.any((r) => r != ConnectivityResult.none);
        if (hasNet) _safeFlush();
      });
    } catch (e, st) {
      debugPrint('[analytics] ServerSink init failed (continuing): $e\n$st');
    }
  }

  /// Records the anon id once so we can attach it as the `X-Anon-Id` header.
  /// Called from `AnalyticsService` after `AnonId.get()`.
  void setAnonIdHeader(String anonId) {
    _anonIdHeader = anonId;
  }

  @override
  Future<void> identify(String userId, Map<String, Object?> props) async {
    // Server-side identity comes from the JWT on the next flush. We still
    // emit a typed `identify` event so the warehouse has an audit trail.
    await track(
      AnalyticsEvent.custom('identify', category: 'auth', requiresConsent: false),
      {'user_id': userId, ...props},
      const {},
    );
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    await track(
      AnalyticsEvent.custom('user_property_set', category: 'auth', requiresConsent: false),
      {'key': key, 'value': value},
      const {},
    );
  }

  @override
  Future<void> track(
    AnalyticsEvent event,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    try {
      _enqueue({
        'name': event.name,
        'type': event.category,
        if (props.isNotEmpty) 'props': props,
        if (ctx.isNotEmpty) 'ctx': ctx,
      });
      if (_queue.length >= _flushThreshold) {
        unawaited(_safeFlush());
      }
    } catch (e) {
      debugPrint('[analytics] ServerSink.track enqueue failed: $e');
    }
  }

  @override
  Future<void> screen(
    String screenName,
    Map<String, Object?> props,
    Map<String, Object?> ctx,
  ) async {
    await track(AnalyticsEvent.screenView, {'screen_name': screenName, ...props}, ctx);
  }

  @override
  Future<void> reset() async {
    // Keep queued events — we still want to deliver any pre-logout activity
    // for that user. Just flush now.
    await _safeFlush();
  }

  /// Immediate best-effort flush. Safe to call from anywhere (e.g. lifecycle
  /// transitions). Never throws.
  Future<void> flush() => _safeFlush();

  /// Cancels timers/subscriptions. Optional — only needed in tests.
  Future<void> dispose() async {
    _periodicTimer?.cancel();
    await _connSub?.cancel();
  }

  // ——— internals ———

  void _enqueue(Map<String, Object?> event) {
    if (_queue.length >= _queueCap) {
      _queue.removeFirst(); // drop oldest on overflow
    }
    _queue.add(event);
    unawaited(_persistQueue());
  }

  Future<void> _safeFlush() async {
    try {
      await _flush();
    } catch (e, st) {
      debugPrint('[analytics] flush swallowed error: $e\n$st');
    }
  }

  Future<void> _flush() async {
    if (_flushing) return;
    if (_queue.isEmpty) return;
    if (_backoffUntil != null && DateTime.now().isBefore(_backoffUntil!)) return;

    _flushing = true;
    try {
      final batch = <Map<String, Object?>>[];
      while (batch.length < _batchSize && _queue.isNotEmpty) {
        batch.add(_queue.removeFirst());
      }
      if (batch.isEmpty) return;

      final token = await _safeGetToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_anonIdHeader != null) 'X-Anon-Id': _anonIdHeader!,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      Response<dynamic> response;
      try {
        response = await _dio.post<dynamic>(
          '$baseUrl/track/batch',
          data: {'events': batch},
          options: Options(headers: headers, responseType: ResponseType.json),
        );
      } on DioException catch (e) {
        // Network or 5xx error: requeue + backoff
        _requeue(batch);
        if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
          _applyBackoff();
        } else if (e.response?.statusCode == 429) {
          _backoffUntil = DateTime.now().add(const Duration(seconds: 30));
        } else {
          _applyBackoff();
        }
        await _persistQueue();
        return;
      }

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        _nextBackoff = const Duration(seconds: 2);
        _backoffUntil = null;
        await _persistQueue();
        // Opportunistically continue if there's more
        if (_queue.isNotEmpty) {
          unawaited(_safeFlush());
        }
        return;
      }

      if (status == 400) {
        // Schema bug — log and drop, retrying will keep failing
        debugPrint('[analytics] /track/batch 400 — dropped ${batch.length} events. '
            'Body: ${response.data}');
        await _persistQueue();
        return;
      }

      if (status == 429) {
        _requeue(batch);
        _backoffUntil = DateTime.now().add(const Duration(seconds: 30));
        await _persistQueue();
        return;
      }

      // Other non-2xx: backoff + retry
      _requeue(batch);
      _applyBackoff();
      await _persistQueue();
    } finally {
      _flushing = false;
    }
  }

  void _requeue(List<Map<String, Object?>> batch) {
    for (final evt in batch.reversed) {
      if (_queue.length >= _queueCap) _queue.removeLast();
      _queue.addFirst(evt);
    }
  }

  void _applyBackoff() {
    _backoffUntil = DateTime.now().add(_nextBackoff);
    final nextMs = (_nextBackoff.inMilliseconds * 2).clamp(2000, 5 * 60 * 1000);
    _nextBackoff = Duration(milliseconds: nextMs);
  }

  Future<String?> _safeGetToken() async {
    try {
      return await getAuthToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Persist tail only to bound IO (and because the head is the next batch)
      final snapshot = _queue.toList();
      await prefs.setString(_persistKey, jsonEncode(snapshot));
    } catch (_) {}
  }

  Future<void> _restorePersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is Map) {
          _queue.add(item.cast<String, Object?>());
        }
      }
    } catch (_) {}
  }
}
