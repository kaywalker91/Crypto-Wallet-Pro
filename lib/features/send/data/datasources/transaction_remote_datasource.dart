
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../../../../core/constants/mock_config.dart';
import '../../../../core/network/web3_client_provider.dart';
import '../../domain/entities/gas_estimate.dart';
import 'mock_transaction_datasource.dart';

part 'transaction_remote_datasource.g.dart';

abstract class TransactionRemoteDataSource {
  Future<Map<GasPriority, GasEstimate>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
    String? tokenAddress,
  });

  Future<String> sendTransaction({
    required SendTransactionParams params,
    required String privateKey,
  });
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final Web3Client _web3Client;

  TransactionRemoteDataSourceImpl(this._web3Client);

  @override
  Future<Map<GasPriority, GasEstimate>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
    String? tokenAddress,
  }) async {
    try {
      final sender = EthereumAddress.fromHex(senderAddress);
      final recipient = EthereumAddress.fromHex(recipientAddress);
      
      // Determine if we are sending ETH or ERC-20
      EthereumAddress? toAddress;
      EtherAmount? value;
      Uint8List? data;

      if (tokenAddress != null) {
        // ERC-20 Transfer
        final token = EthereumAddress.fromHex(tokenAddress);
        toAddress = token;
        value = EtherAmount.zero(); // Value sent to contract is 0

        const erc20Abi = '[{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
        final contract = DeployedContract(ContractAbi.fromJson(erc20Abi, 'ERC20'), token);
        final transferFunction = contract.function('transfer');
        data = transferFunction.encodeCall([recipient, amountInWei]);
      } else {
        // ETH Transfer
        toAddress = recipient;
        value = EtherAmount.inWei(amountInWei);
        data = null;
      }

      // 1. Estimate Gas Limit
      final gasLimit = await _web3Client.estimateGas(
        sender: sender,
        to: toAddress,
        value: value,
        data: data,
      );

      // 2. Get Gas Price (Legacy) or Fee History (EIP-1559)
      // For simplicity in this demo, we'll use getGasPrice and emulate EIP-1559 fields
      // In production, we should use eth_feeHistory or equivalent API
      final etherGasPrice = await _web3Client.getGasPrice();
      final baseGasPrice = etherGasPrice.getInWei;

      // Define multiplier for priorities (Low: 1.0, Medium: 1.2, High: 1.5)
      // This is a simplified heuristic.
      
      GasEstimate createEstimate(double multiplier, BigInt tip) {
        // maxFeePerGas = baseFee * multiplier + tip
        final adjustedBase = (baseGasPrice.toDouble() * multiplier).toInt();
        final maxFee = BigInt.from(adjustedBase) + tip;
        final maxPriority = tip;
        
        // Final estimated fee = gasLimit * maxFee
        final totalFee = gasLimit * maxFee;

        return GasEstimate(
          limit: gasLimit,
          maxFeePerGas: maxFee,
          maxPriorityFeePerGas: maxPriority,
          estimatedFeeInWei: totalFee,
        );
      }

      // Tips (Priority Fees) in Wei (Simplified: 1 Gwei, 2 Gwei, 3 Gwei)
      final tipLow = BigInt.from(1000000000); 
      final tipMedium = BigInt.from(2000000000); 
      final tipHigh = BigInt.from(3000000000); 

      return {
        GasPriority.low: createEstimate(1.0, tipLow),
        GasPriority.medium: createEstimate(1.1, tipMedium),
        GasPriority.high: createEstimate(1.2, tipHigh),
      };
    } catch (e) {
      throw Exception('Failed to estimate gas: $e');
    }
  }

  @override
  Future<String> sendTransaction({
    required SendTransactionParams params,
    required String privateKey,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final sender = credentials.address;
      
      // Determine transaction fields based on tokenAddress
      EthereumAddress? toAddress;
      EtherAmount? value;
      Uint8List? data;

      if (params.tokenAddress != null) {
        // ERC-20 Transfer
        final token = EthereumAddress.fromHex(params.tokenAddress!);
        toAddress = token;
        value = EtherAmount.zero();

        const erc20Abi = '[{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
        final contract = DeployedContract(ContractAbi.fromJson(erc20Abi, 'ERC20'), token);
        final transferFunction = contract.function('transfer');
        final recipient = EthereumAddress.fromHex(params.recipientAddress);
        data = transferFunction.encodeCall([recipient, params.amountInWei]);
      } else {
        // ETH Transfer
        toAddress = EthereumAddress.fromHex(params.recipientAddress);
        value = EtherAmount.inWei(params.amountInWei);
        data = null;
      }

      final transaction = Transaction(
        from: sender,
        to: toAddress,
        value: value,
        data: data,
        maxGas: params.gasEstimate.limit.toInt(),
        maxFeePerGas: EtherAmount.inWei(params.gasEstimate.maxFeePerGas),
        maxPriorityFeePerGas: EtherAmount.inWei(params.gasEstimate.maxPriorityFeePerGas),
        // nonce will be fetched automatically by web3dart if not provided
      );

      final txHash = await _web3Client.sendTransaction(
        credentials,
        transaction,
        chainId: null, // Let web3dart fetch chainId
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to send transaction: $e');
    }
  }
}

@riverpod
TransactionRemoteDataSource transactionRemoteDataSource(Ref ref) {
  // 목업 모드일 경우 MockTransactionDataSource 사용
  if (MockConfig.useMockData || MockConfig.mockTransaction) {
    return MockTransactionDataSource();
  }

  final web3Client = ref.watch(web3ClientProvider);
  return TransactionRemoteDataSourceImpl(web3Client);
}
