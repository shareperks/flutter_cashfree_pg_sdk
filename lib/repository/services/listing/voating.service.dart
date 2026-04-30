import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/voting_listing_model.dart';
import 'package:shareperks/repository/network.dart';

class VotingService {
  static final Dio _dio = createDio(Host.submitApi);

  /// Fetches current voting listing; response matches backend `success` + `item` envelope.
  static Future<VotingListingResponse> fetchVotingListing() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/voting/listing',
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Voting listing: empty response body');
    }
    return VotingListingResponse.fromJson(data);
  }

  static Future<VotingSubmitResponse> submitVot(
    String votingId,
    String brandId,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/voting/submit',
      data: {'votingId': votingId, 'brandsId': brandId},
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Voting submit: empty response body');
    }
    return VotingSubmitResponse.fromJson(data);
  }
}
