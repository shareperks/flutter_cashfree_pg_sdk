// holding-api: POST /smallcase/connect

class SmallcaseConnectResponse {
  final SmallcaseTransactionResponse transactionResponse;
  final String token;
  final String transactionId;

  SmallcaseConnectResponse({
    required this.transactionResponse,
    required this.token,
    required this.transactionId,
  });

  factory SmallcaseConnectResponse.fromJson(Map<String, dynamic> json) {
    return SmallcaseConnectResponse(
      transactionResponse: SmallcaseTransactionResponse.fromJson(
        json['transactionResponse'] as Map<String, dynamic>,
      ),
      token: json['token'] as String,
      transactionId: json['transactionId'] as String,
    );
  }
}

class SmallcaseTransactionResponse {
  final bool success;
  final dynamic errors;
  final SmallcaseConnectTransactionData? data;

  SmallcaseTransactionResponse({
    required this.success,
    this.errors,
    this.data,
  });

  factory SmallcaseTransactionResponse.fromJson(Map<String, dynamic> json) {
    return SmallcaseTransactionResponse(
      success: json['success'] as bool,
      errors: json['errors'],
      data: json['data'] != null
          ? SmallcaseConnectTransactionData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class SmallcaseConnectTransactionData {
  final String transactionId;
  final DateTime expireAt;

  SmallcaseConnectTransactionData({
    required this.transactionId,
    required this.expireAt,
  });

  factory SmallcaseConnectTransactionData.fromJson(Map<String, dynamic> json) {
    return SmallcaseConnectTransactionData(
      transactionId: json['transactionId'] as String,
      expireAt: DateTime.parse(json['expireAt'] as String),
    );
  }
}

// holding-api: POST /smallcase/fetch-holding-transaction

class FetchHoldingTransactionPayload {
  final String transactionToken;

  FetchHoldingTransactionPayload({required this.transactionToken});

  Map<String, dynamic> toJson() => {'transactionToken': transactionToken};
}

class FetchHoldingTransactionResponse {
  final SmallcaseTransactionResponse transactionResponse;
  final String holdingTransactionId;

  FetchHoldingTransactionResponse({
    required this.transactionResponse,
    required this.holdingTransactionId,
  });

  factory FetchHoldingTransactionResponse.fromJson(Map<String, dynamic> json) {
    return FetchHoldingTransactionResponse(
      transactionResponse: SmallcaseTransactionResponse.fromJson(
        json['transactionResponse'] as Map<String, dynamic>,
      ),
      holdingTransactionId: json['holdingTransactionId'] as String,
    );
  }
}

// holding-api: POST /smallcase/fetch-user-holdings/:userId
// holding-api: GET /holdings/:userId (list of the same snapshot shape + reqReimport)

class FetchUserHoldingsResponse {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String brokerCode;
  final String depository;
  final DateTime snapshotDate;
  final String? boId;
  final String? dpId;
  final String? dpName;
  final String clientId;
  final String? pan;
  final List<UserHoldingLine> holdings;
  final bool primary;
  /// Present on [GET /holdings/:userId]; omitted on smallcase fetch-user-holdings.
  final bool? reqReimport;

  FetchUserHoldingsResponse({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.brokerCode,
    required this.depository,
    required this.snapshotDate,
    this.boId,
    this.dpId,
    this.dpName,
    required this.clientId,
    this.pan,
    required this.holdings,
    required this.primary,
    this.reqReimport,
  });

  factory FetchUserHoldingsResponse.fromJson(Map<String, dynamic> json) {
    return FetchUserHoldingsResponse(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'].toString(),
      brokerCode: json['brokerCode'] as String,
      depository: json['depository'] as String,
      snapshotDate: DateTime.parse(json['snapshotDate'] as String),
      boId: _nullableString(json['bo_id']),
      dpId: _nullableString(json['dp_id']),
      dpName: _nullableString(json['dp_name']),
      clientId: json['client_id'] as String,
      pan: _nullableString(json['pan']),
      holdings: (json['holdings'] as List<dynamic>)
          .map(
            (e) => UserHoldingLine.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      primary: json['primary'] as bool,
      reqReimport: json['reqReimport'] as bool?,
    );
  }
}

class UserHoldingLine {
  final String isin;
  final String logo;
  final String name;
  final double price;
  final double value;
  /// CDSL rows may be fractional (e.g. mutual fund units).
  final double quantity;
  final int holdingDays;
  final double? averagePrice;

  UserHoldingLine({
    required this.isin,
    required this.logo,
    required this.name,
    required this.price,
    required this.value,
    required this.quantity,
    required this.holdingDays,
    this.averagePrice,
  });

  factory UserHoldingLine.fromJson(Map<String, dynamic> json) {
    return UserHoldingLine(
      isin: json['isin'] as String,
      logo: json['logo'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      holdingDays: (json['holdingDays'] as num).round(),
      averagePrice: json['averagePrice'] != null
          ? (json['averagePrice'] as num).toDouble()
          : null,
    );
  }
}

// holding-api: PUT /holdings/:userId/mark-as-primary/:holdingId

class MarkHoldingAsPrimaryResponse {
  final bool result;

  MarkHoldingAsPrimaryResponse({required this.result});

  factory MarkHoldingAsPrimaryResponse.fromJson(Map<String, dynamic> json) {
    return MarkHoldingAsPrimaryResponse(
      result: json['result'] as bool,
    );
  }
}

// holding-api: DELETE /holdings/:userId/discard/:holdingId

class DiscardHoldingResponse {
  final bool result;
  final String message;
  final String status;
  final int code;
  final DateTime timestamp;

  DiscardHoldingResponse({
    required this.result,
    required this.message,
    required this.status,
    required this.code,
    required this.timestamp,
  });

  factory DiscardHoldingResponse.fromJson(Map<String, dynamic> json) {
    return DiscardHoldingResponse(
      result: json['result'] as bool,
      message: json['message'] as String,
      status: json['status'] as String,
      code: (json['code'] as num).round(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    return t;
  }
  return value.toString();
}
