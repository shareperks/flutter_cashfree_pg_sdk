import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scgateway_flutter_plugin/scgateway_flutter_plugin.dart';
import 'package:shareperks/constants/holdings.dart';
import 'package:shareperks/function/localstorage.dart';
import 'package:shareperks/repository/services/holding/holding.service.dart';
import 'package:shareperks/repository/services/holding/holding_model.dart';

class SmallcaseGateway {
  static const String gatewayName = 'shareperks';

  static Future<void> _configure(HoldingBroker? broker) async {
    await ScgatewayFlutterPlugin.setConfigEnvironment(
      GatewayEnvironment.PRODUCTION,
      gatewayName,
      false,
      broker != null ? [broker.brokerKey] : [],
      isAmoenabled: false,
    );
  }

  static Future<void> importHolding(
    HoldingBroker broker,
    Function(bool) inProgress,
    Function(bool) isSuccess,
  ) async {
    try {
      inProgress.call(true);
      await _configure(broker);
      SmallcaseConnectResponse conTrxData =
          await HoldingService.connectSmallcase();

      String? initResponse = await ScgatewayFlutterPlugin.initGateway(
        conTrxData.token,
      );
      print(initResponse);
      String? transactionData =
          await ScgatewayFlutterPlugin.triggerGatewayTransaction(
            conTrxData.transactionId,
          );
      if (transactionData == null) {
        throw Exception('Transaction ID is null');
      }
      final fetchHoldingsSmallcaseToken = _getSmallcaseToken(
        transactionData.toString(),
      );
      print(fetchHoldingsSmallcaseToken);

      await HoldingService.fetchUserHoldings(fetchHoldingsSmallcaseToken);
      await HoldingService.ensurePrimaryHoldingIfNeeded();
      isSuccess(true);
    } catch (e) {
      if (e is DioException) {
        Fluttertoast.showToast(msg: e.response?.data['message']);
      }
    } finally {
      inProgress.call(false);
    }
  }

  static String _getSmallcaseToken(String data) {
    final payloadData = jsonDecode(data.toString());
    if (payloadData.toString().contains('smallcaseAuthToken')) {
      final dataDecoded = jsonDecode(payloadData['data'].toString());
      return dataDecoded['smallcaseAuthToken'] as String;
    }
    return payloadData['data'] as String;
  }
}
