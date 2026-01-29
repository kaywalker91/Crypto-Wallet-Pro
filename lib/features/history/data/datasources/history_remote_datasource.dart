
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/constants/env_config.dart';
import '../../../../core/constants/mock_config.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/transaction_model.dart';
import 'mock_history_datasource.dart';

part 'history_remote_datasource.g.dart';

abstract class HistoryRemoteDataSource {
  Future<List<TransactionModel>> getHistory({
    required String address,
    required NetworkType network,
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final Dio _dio;

  HistoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<TransactionModel>> getHistory({
    required String address,
    required NetworkType network,
  }) async {
    final url = EnvConfig.getRpcUrl(network);

    try {
      // 1. Fetch Sent Transfers (fromAddress = user)
      final responseSent = await _dio.post(
        url,
        data: {
          "id": 1,
          "jsonrpc": "2.0",
          "method": "alchemy_getAssetTransfers",
          "params": [
            {
              "fromBlock": "0x0",
              "toBlock": "latest",
              "fromAddress": address,
              "category": ["external", "erc20", "erc721", "erc1155"],
              "withMetadata": true,
              "excludeZeroValue": true,
              "maxCount": "0x64" // 100
            }
          ]
        },
      );
      
      final sentTransfers = _parseTransfers(responseSent.data, address);

      // 2. Fetch Received Transfers (toAddress = user)
      final responseReceived = await _dio.post(
        url,
        data: {
          "id": 1,
          "jsonrpc": "2.0",
          "method": "alchemy_getAssetTransfers",
          "params": [
            {
              "fromBlock": "0x0",
              "toBlock": "latest",
              "toAddress": address,
              "category": ["external", "erc20", "erc721", "erc1155"],
              "withMetadata": true,
              "excludeZeroValue": true,
              "maxCount": "0x64" // 100
            }
          ]
        },
      );

      final receivedTransfers = _parseTransfers(responseReceived.data, address);

      // 3. Combine and sort
      final allTransfers = [...sentTransfers, ...receivedTransfers];
      allTransfers.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending
      
      return allTransfers;

    } catch (e) {
      throw Exception('Failed to fetch transaction history: $e');
    }
  }

  List<TransactionModel> _parseTransfers(Map<String, dynamic> data, String userAddress) {
    if (data['result'] == null || data['result']['transfers'] == null) {
      return [];
    }

    final transfers = data['result']['transfers'] as List;
    return transfers
        .map((t) => TransactionModel.fromJson(t, userAddress))
        .toList();
  }
}

@riverpod
HistoryRemoteDataSource historyRemoteDataSource(Ref ref) {
  // 목업 모드일 경우 MockHistoryDataSource 사용
  if (MockConfig.useMockData || MockConfig.mockHistory) {
    return MockHistoryDataSource();
  }

  final dio = ref.watch(dioProvider);
  return HistoryRemoteDataSourceImpl(dio);
}
