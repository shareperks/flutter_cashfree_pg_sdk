/// `PATCH /rewards/my-claimed/giftcard/:claimedId/toggle-redeemed`
/// and `PATCH /rewards/my-claimed/promocode/:claimedId/toggle-redeemed` —
/// same `{ success, data }` envelope.
class ToggleRedeemedResponse {
  ToggleRedeemedResponse({this.success, this.data});

  final bool? success;
  final ToggleRedeemedData? data;

  factory ToggleRedeemedResponse.fromJson(Map<String, dynamic> json) {
    return ToggleRedeemedResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map<String, dynamic>
          ? ToggleRedeemedData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (data != null) 'data': data!.toJson(),
      };
}

class ToggleRedeemedData {
  ToggleRedeemedData({this.status, this.isUsed});

  /// Request succeeded (server-side toggle applied).
  final bool? status;

  /// Current redeemed / used flag after toggle.
  final bool? isUsed;

  factory ToggleRedeemedData.fromJson(Map<String, dynamic> json) {
    return ToggleRedeemedData(
      status: json['status'] as bool?,
      isUsed: json['isUsed'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'isUsed': isUsed,
      };
}
