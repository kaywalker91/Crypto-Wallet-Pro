import 'dart:math';

import '../../../../core/constants/mock_config.dart';
import '../../domain/entities/gas_estimate.dart';
import 'transaction_remote_datasource.dart';

/// 목업 트랜잭션 데이터 소스
///
/// API 호출 없이 트랜잭션 전송 기능을 테스트할 수 있도록 목업 데이터 제공
class MockTransactionDataSource implements TransactionRemoteDataSource {
  final _random = Random();

  MockTransactionDataSource();

  @override
  Future<Map<GasPriority, GasEstimate>> getGasEstimates({
    required String senderAddress,
    required String recipientAddress,
    required BigInt amountInWei,
    String? tokenAddress,
  }) async {
    // 실제 API 응답 시간 시뮬레이션
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Failed to estimate gas');
    }

    // 기본 가스 리밋 (ETH: 21000, ERC20: 65000)
    final gasLimit = tokenAddress != null ? BigInt.from(65000) : BigInt.from(21000);

    // 목업 가스 가격 (약 30 Gwei)
    final baseGasPrice = BigInt.from(30 * 1e9);

    return {
      GasPriority.low: GasEstimate(
        limit: gasLimit,
        maxFeePerGas: baseGasPrice,
        maxPriorityFeePerGas: BigInt.from(1 * 1e9), // 1 Gwei
        estimatedFeeInWei: gasLimit * baseGasPrice,
      ),
      GasPriority.medium: GasEstimate(
        limit: gasLimit,
        maxFeePerGas: BigInt.from(35 * 1e9),
        maxPriorityFeePerGas: BigInt.from(2 * 1e9), // 2 Gwei
        estimatedFeeInWei: gasLimit * BigInt.from(35 * 1e9),
      ),
      GasPriority.high: GasEstimate(
        limit: gasLimit,
        maxFeePerGas: BigInt.from(45 * 1e9),
        maxPriorityFeePerGas: BigInt.from(3 * 1e9), // 3 Gwei
        estimatedFeeInWei: gasLimit * BigInt.from(45 * 1e9),
      ),
    };
  }

  @override
  Future<String> sendTransaction({
    required SendTransactionParams params,
    required String privateKey,
  }) async {
    // 트랜잭션 전송 시간 시뮬레이션 (조금 더 긴 지연)
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs * 2));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Transaction failed - insufficient funds or network error');
    }

    // 목업 트랜잭션 해시 생성
    final mockHash = _generateMockTxHash();
    return mockHash;
  }

  String _generateMockTxHash() {
    const hexChars = '0123456789abcdef';
    final buffer = StringBuffer('0x');
    for (var i = 0; i < 64; i++) {
      buffer.write(hexChars[_random.nextInt(16)]);
    }
    return buffer.toString();
  }

  bool _shouldFail() {
    return _random.nextDouble() < MockConfig.errorProbability;
  }
}
