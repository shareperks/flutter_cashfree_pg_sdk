import 'home_common_models.dart';

/// `tab` query for `GET /wallet/transitions` — `ALL`, `PAYOUT`, or `EARNING`.
enum WalletTransitionsTab {
  all('ALL'),
  payout('PAYOUT'),
  earning('EARNING');

  const WalletTransitionsTab(this.queryValue);

  final String queryValue;

  /// Wallet history UI: 0 = All, 1 = Withdrawals, 2 = Earnings.
  static WalletTransitionsTab fromHistoryTabIndex(int index) {
    switch (index) {
      case 1:
        return WalletTransitionsTab.payout;
      case 2:
        return WalletTransitionsTab.earning;
      default:
        return WalletTransitionsTab.all;
    }
  }
}

/// `GET /wallet/info` — `{ wallet, transactions }`.
class WalletInfoResponse {
  WalletInfoResponse({this.wallet, List<WalletTransaction>? transactions})
    : transactions = transactions ?? const [];

  final WalletSummary? wallet;
  final List<WalletTransaction> transactions;

  factory WalletInfoResponse.fromJson(Map<String, dynamic> json) {
    return WalletInfoResponse(
      wallet: json['wallet'] is Map<String, dynamic>
          ? WalletSummary.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
      transactions: _mapTransactions(json['transactions']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (wallet != null) 'wallet': wallet!.toJson(),
    'transactions': transactions.map((e) => e.toJson()).toList(),
  };

  static List<WalletTransaction> _mapTransactions(dynamic raw) {
    return WalletTransaction.listFromJsonArray(raw);
  }
}

/// `wallet` object on [WalletInfoResponse].
class WalletSummary {
  WalletSummary({
    this.balance,
    this.totalLifeEarn,
    this.totalCashbackEarn,
    this.totalReferEarn,
    this.totalPendingAmount,
    this.totalPaidAmount,
    this.maxPayPercent,
  });

  final double? balance;
  final double? totalLifeEarn;
  final double? totalCashbackEarn;
  final double? totalReferEarn;
  final double? totalPendingAmount;
  final double? totalPaidAmount;

  /// Max share of gift-card payable via wallet (e.g. 70).
  /// From `WALLET_MAX_PAY_PERCENT`; app defaults to 70 when absent.
  final double? maxPayPercent;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: parseJsonDouble(json['balance']),
      totalLifeEarn: parseJsonDouble(json['totalLifeEarn']),
      totalCashbackEarn: parseJsonDouble(json['totalCashbackEarn']),
      totalReferEarn: parseJsonDouble(json['totalReferEarn']),
      totalPendingAmount: parseJsonDouble(json['totalPendingAmount']),
      totalPaidAmount: parseJsonDouble(json['totalPaidAmount']),
      maxPayPercent: parseJsonDouble(
        json['maxPayPercent'] ?? json['max_pay_percent'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'totalLifeEarn': totalLifeEarn,
    'totalCashbackEarn': totalCashbackEarn,
    'totalReferEarn': totalReferEarn,
    'totalPendingAmount': totalPendingAmount,
    'totalPaidAmount': totalPaidAmount,
    if (maxPayPercent != null) 'maxPayPercent': maxPayPercent,
  };
}

/// One row in `transactions`.
///
/// **Full shape** (credits): `id`, `amount`, `status`, `reason`, `type`, `title`,
/// `source`, `date`, `time`.
///
/// **Minimal shape** (e.g. debits): may omit `status`, `type`, `title`, `source`
/// and use `reason` alone such as `DEBIT`.
class WalletTransaction {
  WalletTransaction({
    this.id,
    this.amount,
    this.status,
    this.reason,
    this.type,
    this.title,
    this.source,
    this.date,
    this.time,
  });

  final String? id;
  final double? amount;

  /// When present: e.g. `PENDING`, `COMPLETED`.
  final String? status;

  /// Reward / movement label from API: e.g. `CASHBACK`, or `DEBIT` on sparse rows.
  final String? reason;

  /// When present: e.g. `CREDIT`, `DEBIT`.
  final String? type;

  final String? title;
  final String? source;
  final String? date;
  final String? time;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String?,
      amount: parseJsonDouble(json['amount']),
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      source: json['source'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
    );
  }

  /// Parses a top-level JSON array (e.g. `GET /wallet/transitions`,
  /// `GET /wallet/cashback-transitions`, `GET /wallet/payout-transitions`).
  static List<WalletTransaction> listFromJsonArray(dynamic raw) {
    if (raw is! List<dynamic>) return const <WalletTransaction>[];
    return raw
        .whereType<Map>()
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `true` when [type] or [reason] is `DEBIT` (case-insensitive).
  bool get isDebit {
    final t = (type ?? '').toUpperCase();
    final r = (reason ?? '').toUpperCase();
    return t == 'DEBIT' || r == 'DEBIT';
  }

  /// Primary line for UI when [title] is absent (e.g. debit-only payload).
  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final r = reason?.trim();
    if (r != null && r.isNotEmpty) return r;
    return 'Transaction';
  }

  /// `date` and `time` joined when both exist.
  String get displayDateTime {
    final d = date?.trim();
    final tm = time?.trim();
    if (d != null && d.isNotEmpty && tm != null && tm.isNotEmpty) {
      return '$d · $tm';
    }
    if (d != null && d.isNotEmpty) return d;
    if (tm != null && tm.isNotEmpty) return tm;
    return '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'status': status,
    'reason': reason,
    'type': type,
    'title': title,
    'source': source,
    'date': date,
    'time': time,
  };
}
