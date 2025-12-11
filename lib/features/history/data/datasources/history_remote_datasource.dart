import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/env_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';


abstract class HistoryRemoteDataSource {
  Future<List<TransactionModel>> getTransfers({
    required NetworkType network,
    String? fromAddress,
    String? toAddress,
    required String userAddressForParsing, // To determine sent/received type
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final http.Client client;

  HistoryRemoteDataSourceImpl(this.client);

  @override
  Future<List<TransactionModel>> getTransfers({
    required NetworkType network,
    String? fromAddress,
    String? toAddress,
    required String userAddressForParsing,
  }) async {
    final url = EnvConfig.getRpcUrl(network);
    
    final payload = {
      "id": 1,
      "jsonrpc": "2.0",
      "method": "alchemy_getAssetTransfers",
      "params": [
        {
          "fromBlock": "0x0",
          "toBlock": "latest",
          if (fromAddress != null) "fromAddress": fromAddress,
          if (toAddress != null) "toAddress": toAddress,
          "category": ["external", "erc20"],
          "withMetadata": true,
          "excludeZeroValue": true,
          "maxCount": "0x3e8", // 1000
          "order": "desc" // Alchemy specific? No, need to sort manually usually, but recent first is preferred if possible. Alchemy returns ascending by default.
        }
      ]
    };

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          throw ServerException();
        }

        final result = data['result'];
        if (result == null || result['transfers'] == null) {
          return [];
        }

        final transfers = (result['transfers'] as List)
            .map((t) => TransactionModel.fromJson(t, userAddressForParsing))
            .toList();
            
        return transfers;
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}
