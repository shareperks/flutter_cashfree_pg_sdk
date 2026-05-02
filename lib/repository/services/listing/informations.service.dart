import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/information_faq_model.dart';
import 'package:shareperks/repository/network.dart';

/// Listing API: help / FAQ content.
class InformationsService {
  InformationsService._();

  static final Dio _dio = createDio(Host.submitApi);

  /// FAQ list.
  /// Adjust [FaqsApi.path] if the backend route differs.
  static Future<InformationFaqListResponse> fetchFaqs({
    String? type,
    int page = 1,
    int limit = 200,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      "/api/faqs",
      queryParameters: <String, dynamic>{
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'limit': limit,
      },
    );

    final body = response.data;
    if (body == null) {
      throw StateError('FAQs: empty response body');
    }
    return InformationFaqListResponse.fromJson(body);
  }
}
