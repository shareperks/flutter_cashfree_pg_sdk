import 'package:dio/dio.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/network.dart';
import 'package:shareperks/repository/services/holding/holding_model.dart';

class HoldingService {
  static final Dio _dio = createDio(Host.holdingApi);

  /// POST /smallcase/connect
  static Future<SmallcaseConnectResponse> connectSmallcase() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/smallcase/connect',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return SmallcaseConnectResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /smallcase/fetch-holding-transaction
  static Future<FetchHoldingTransactionResponse> fetchHoldingTransaction(
    FetchHoldingTransactionPayload payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/smallcase/fetch-holding-transaction',
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return FetchHoldingTransactionResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /smallcase/fetch-user-holdings/:userId
  static Future<FetchUserHoldingsResponse> fetchUserHoldings(
    String transactionToken,
  ) async {
    try {
      String? userID = LocalStorage.getString("userId");
      final response = await _dio.post<Map<String, dynamic>>(
        '/smallcase/fetch-user-holdings/$userID',
        data: {"transactionToken": transactionToken},
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return FetchUserHoldingsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /smallcase/refresh-holding-transaction/:holdingId
  ///
  /// Refreshes the holdings snapshot identified by [holdingSnapshotId]
  /// (`FetchUserHoldingsResponse.id`). Returns the updated snapshot.
  static Future<FetchUserHoldingsResponse> refreshHoldingTransaction(
    String holdingSnapshotId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/smallcase/refresh-holding-transaction/$holdingSnapshotId',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return FetchUserHoldingsResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /holdings/:userId
  static Future<List<FetchUserHoldingsResponse>> getHoldings() async {
    try {
      String? userID = LocalStorage.getString("userId");
      final response = await _dio.get<dynamic>('/holdings/$userID');
      final data = response.data;
      if (data is! List) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Expected JSON array',
        );
      }
      return data
          .map(
            (e) => FetchUserHoldingsResponse.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// GET /holdings/:userId/primary — snapshot for the user’s primary linked account.
  static Future<FetchUserHoldingsResponse> getPrimaryHoldings() async {
    try {
      final String? userID = LocalStorage.getString("userId");
      final response = await _dio.get<Map<String, dynamic>>(
        '/holdings/$userID/primary',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return FetchUserHoldingsResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /holdings/:userId/mark-as-primary/:holdingId
  ///
  /// [holdingId] is the holdings snapshot `id` (e.g. from [FetchUserHoldingsResponse.id]).
  static Future<MarkHoldingAsPrimaryResponse> markHoldingAsPrimary(
    String holdingId,
  ) async {
    try {
      final String? userID = LocalStorage.getString("userId");
      final response = await _dio.put<Map<String, dynamic>>(
        '/holdings/$userID/mark-as-primary/$holdingId',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return MarkHoldingAsPrimaryResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /holdings/:userId/discard/:holdingId
  ///
  /// [holdingId] is the holdings snapshot `id` to remove from the linked account list.
  static Future<DiscardHoldingResponse> discardHolding(String holdingId) async {
    try {
      final String? userID = LocalStorage.getString("userId");
      final response = await _dio.delete<Map<String, dynamic>>(
        '/holdings/$userID/discard/$holdingId',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return DiscardHoldingResponse.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      rethrow;
    }
  }

  /// POST /holdings/import
  ///
  /// Matches curl:
  /// - form field **file**: PDF or Excel (.xlsx)
  /// - userId, brokerCode, depository, password
  ///
  /// Returns a queued job: `{ id, status: "PENDING", message }`
  /// or throws a [DioException] for non-2xx responses.
  static Future<HoldingImportJob> importHoldings({
    required String filePath,
    required String brokerCode,
    required String depository,
    String password = '',
    String? userId,
  }) async {
    try {
      final String? resolvedUserId = userId ?? LocalStorage.getString("userId");
      if (resolvedUserId == null || resolvedUserId.trim().isEmpty) {
        throw StateError('Missing userId in LocalStorage');
      }

      final formData = FormData.fromMap({
        // IMPORTANT: backend expects field name "file"
        'file': await MultipartFile.fromFile(filePath),
        'userId': resolvedUserId,
        'brokerCode': brokerCode,
        'depository': depository,
        'password': password,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/holdings/import',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }

      final parsed = HoldingImportResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
      final job = parsed.job;
      if (job == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: parsed.message ?? 'Import failed',
        );
      }
      return job;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /holdings/import/:id
  static Future<HoldingImportResponse> getImportStatus(String importId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/holdings/import/$importId',
      );
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response body',
        );
      }
      return HoldingImportResponse.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      rethrow;
    }
  }
}
