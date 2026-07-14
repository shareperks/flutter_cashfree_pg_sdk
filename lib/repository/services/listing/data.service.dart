import 'package:dio/dio.dart';
import 'package:shareperks/repository/host.dart';
import 'package:shareperks/repository/models/HomeDataModel.dart';
import 'package:shareperks/repository/models/brand_list_model.dart';
import 'package:shareperks/repository/models/reward_list_model.dart';
import 'package:shareperks/repository/models/rewards_by_brand_model.dart';
import 'package:shareperks/repository/models/rewards_by_company_model.dart';
import 'package:shareperks/repository/models/unlocked_perks_model.dart';
import 'package:shareperks/repository/network.dart';

class ListingDataService {
  static final Dio _dio = createDio(Host.listingUrl);
  // /home-data
  static Future<HomeDataModel> getHomeData() async {
    final response = await _dio.get('/home-data');
    return HomeDataModel.fromJson(response.data);
  }

  // /catalogs/categories
  static Future<CategoryListResponse> getCategoryList() async {
    final response = await _dio.get('/catalogs/categories');
    return CategoryListResponse.fromJson(response.data);
  }

  // {{baseUrl}}/rewards/by-category/:categoryId?search=&sort=a-z
  static Future<RewardListResponse> getCategoryRewardList({
    required String categoryId,
    String? search,
    String? sort = "a-z",
  }) async {
    final response = await _dio.get(
      '/rewards/by-category/$categoryId',
      queryParameters: {"search": search, "sort": sort},
    );
    return RewardListResponse.fromJson(response.data);
  }

  // {{baseUrl}}/unlocked-perks
  static Future<UnlockedPerksResponse> getUnlockedPerks({
    String? search,
    String? sort = "a-z",
  }) async {
    final response = await _dio.get(
      '/unlocked-perks',
      queryParameters: {"search": search, "sort": sort},
    );
    return UnlockedPerksResponse.fromJson(response.data);
  }

  //  '/rewards/top-perks',
  static Future<RewardListResponse> getTopPerks({
    String? search,
    String? sort = "a-z",
    required String type,
  }) async {
    final response = await _dio.get(
      '/rewards/top-perks',
      queryParameters: {"search": search, "sort": sort, "type": type},
    );
    return RewardListResponse.fromJson(response.data);
  }

  /// `GET /rewards/search?search=&sort=a-z&type=` — gift cards, cashback, promo codes.
  static Future<RewardListResponse> searchRewards({
    String? search,
    String sort = 'a-z',
    String? type,
  }) async {
    final query = <String, dynamic>{
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final response = await _dio.get(
      '/rewards/search',
      queryParameters: query,
    );
    return RewardListResponse.fromJson(response.data);
  }

  //  '/rewards/$type',
  static Future<RewardListResponse> getTypePerk({
    String? search,
    String? sort = "a-z",
    required String type,
  }) async {
    final response = await _dio.get(
      '/rewards/$type',
      queryParameters: {"search": search, "sort": sort},
    );
    return RewardListResponse.fromJson(response.data);
  }

  static Future<BrandListResponse> getTopBrands({
    String? search,
    String? sort = "a-z",
  }) async {
    final response = await _dio.get(
      '/catalogs/top-brands',
      queryParameters: {"search": search, "sort": sort},
    );
    return BrandListResponse.fromJson(response.data);
  }

  static Future<RewardsByBrandResponse> getRewardsByBrandId({
    required String brandId,
    String? search,
    String? sort = "a-z",
  }) async {
    final response = await _dio.get(
      '/rewards/by-brand/$brandId',
      queryParameters: {"search": search, "sort": sort},
    );
    return RewardsByBrandResponse.fromJson(response.data);
  }

  static Future<RewardsByCompanyResponse> getRewardsByCompanyId({
    required String companyId,
    String? search,
    String? sort = "a-z",
  }) async {
    final response = await _dio.get(
      '/rewards/by-company/$companyId',
      queryParameters: {"search": search, "sort": sort},
    );
    return RewardsByCompanyResponse.fromJson(response.data);
  }
}
