
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';
import '../../../../core/network/web3_client_provider.dart';
import '../../domain/entities/gas_estimate.dart';

part 'transaction_remote_datasource.g.dart';

abstract class TransactionRemoteDataSource {
  Future<Map<GasPriority, GasEstimate>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
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
  }) async {
    try {
      final sender = EthereumAddress.fromHex(senderAddress);
      final recipient = EthereumAddress.fromHex(recipientAddress);
      final amount = EtherAmount.inWei(amountInWei);

      // 1. Estimate Gas Limit
      final gasLimit = await _web3Client.estimateGas(
        sender: sender,
        to: recipient,
        value: amount,
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
      final transaction = Transaction(
        from: sender,
        to: EthereumAddress.fromHex(params.recipientAddress),
        value: EtherAmount.inWei(params.amountInWei),
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
TransactionRemoteDataSource transactionRemoteDataSource(TransactionRemoteDataSourceRef ref) {
  final web3Client = ref.watch(web3ClientProvider);
  return TransactionRemoteDataSourceImpl(web3Client);
}
