import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';
import 'package:shareperks/repository/network.dart';

class HomeDataService {
  static final Dio _dio = createDio(Host.listingUrl);

  static Future<HomeDataModel> getHomeData() async {
    final response = await _dio.get('/home-data');
    return HomeDataModel.fromJson(response.data);
  }
}
