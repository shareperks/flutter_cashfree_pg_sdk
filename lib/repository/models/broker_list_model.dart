import 'home_common_models.dart';

/// Paginated broker search response from `GET /brokers`.
class BrokerListResponse {
  int? page;
  int? size;
  int? totalItems;
  int? totalPages;
  List<BrokerItem>? data;

  BrokerListResponse({
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
    this.data,
  });

  BrokerListResponse.fromJson(Map<String, dynamic> json) {
    page = parseJsonInt(json['page']);
    size = parseJsonInt(json['size']);
    totalItems = parseJsonInt(json['total_items']);
    totalPages = parseJsonInt(json['total_pages']);
    if (json['data'] != null) {
      data = <BrokerItem>[];
      for (final v in json['data'] as List<dynamic>) {
        data!.add(BrokerItem.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'total_items': totalItems,
      'total_pages': totalPages,
      if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
    };
  }
}

class BrokerItem {
  String? symbol;
  String? nameOfCompany;
  String? series;
  String? dateOfListing;
  int? paidUpValue;
  int? marketLot;
  String? isinNumber;
  int? faceValue;

  BrokerItem({
    this.symbol,
    this.nameOfCompany,
    this.series,
    this.dateOfListing,
    this.paidUpValue,
    this.marketLot,
    this.isinNumber,
    this.faceValue,
  });

  BrokerItem.fromJson(Map<String, dynamic> json) {
    symbol = json['symbol'] as String?;
    nameOfCompany = json['name_of_company'] as String?;
    series = json['series'] as String?;
    dateOfListing = json['date_of_listing'] as String?;
    paidUpValue = parseJsonInt(json['paid_up_value']);
    marketLot = parseJsonInt(json['market_lot']);
    isinNumber = json['isin_number'] as String?;
    faceValue = parseJsonInt(json['face_value']);
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name_of_company': nameOfCompany,
      'series': series,
      'date_of_listing': dateOfListing,
      'paid_up_value': paidUpValue,
      'market_lot': marketLot,
      'isin_number': isinNumber,
      'face_value': faceValue,
    };
  }
}
