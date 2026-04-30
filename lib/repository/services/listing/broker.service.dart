import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/broker_list_model.dart';
import 'package:shareperks/repository/network.dart';

class BrokerService {
  static final Dio _dio = createDio(Host.brokerUrl);

  /// `GET /brokers?search=...` — see [BrokerListResponse].
  static Future<BrokerListResponse> searchBrokers({
    required String search,
    int page = 1,
    int size = 10,
  }) async {
    final response = await _dio.get(
      '/brokers',
      queryParameters: {'search': search, 'page': page, 'size': size},
    );
    return BrokerListResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
