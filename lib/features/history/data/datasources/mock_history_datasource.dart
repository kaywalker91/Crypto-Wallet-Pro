import '../../../../core/constants/env_config.dart';
import '../../../../core/constants/mock_config.dart';
import '../../domain/entities/transaction_entity.dart';
import '../models/transaction_model.dart';
import 'history_remote_datasource.dart';

/// 목업 트랜잭션 히스토리 데이터 소스
///
/// API 호출 없이 트랜잭션 히스토리 기능을 테스트할 수 있도록 목업 데이터 제공
class MockHistoryDataSource implements HistoryRemoteDataSource {
  MockHistoryDataSource();

  @override
  Future<List<TransactionModel>> getHistory({
    required String address,
    required NetworkType network,
  }) async {
    // 실제 API 응답 시간 시뮬레이션
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Failed to fetch transaction history');
    }

    final now = DateTime.now();

    return [
      // 받은 ETH
      TransactionModel(
        hash: '0x1234567890abcdef1234567890abcdef12345678901234567890abcdef123456',
        uniqueId: '0x1234...56-0',
        from: '0x742d35Cc6634C0532925a3b844Bc9e7595f5bC16',
        to: address,
        value: 0.5,
        asset: 'ETH',
        category: 'external',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: TransactionType.received,
      ),
      // 보낸 ETH
      TransactionModel(
        hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        uniqueId: '0xabcdef...90-0',
        from: address,
        to: '0x8ba1f109551bd432803012645Ac136ddd64dba72',
        value: 0.1,
        asset: 'ETH',
        category: 'external',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: TransactionType.sent,
      ),
      // 받은 USDT
      TransactionModel(
        hash: '0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba09876543',
        uniqueId: '0xfedcba...43-0',
        from: '0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5',
        to: address,
        value: 500.0,
        asset: 'USDT',
        category: 'erc20',
        timestamp: now.subtract(const Duration(days: 1)),
        type: TransactionType.received,
      ),
      // 보낸 USDC
      TransactionModel(
        hash: '0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba',
        uniqueId: '0x987654...ba-0',
        from: address,
        to: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
        value: 100.0,
        asset: 'USDC',
        category: 'erc20',
        timestamp: now.subtract(const Duration(days: 2)),
        type: TransactionType.sent,
      ),
      // 받은 NFT
      TransactionModel(
        hash: '0x5555555555555555555555555555555555555555555555555555555555555555',
        uniqueId: '0x555555...55-0',
        from: '0x0000000000000000000000000000000000000000',
        to: address,
        value: 1.0,
        asset: 'CryptoPunk #1234',
        category: 'erc721',
        timestamp: now.subtract(const Duration(days: 3)),
        type: TransactionType.received,
      ),
      // UNI Swap
      TransactionModel(
        hash: '0xaaaa111122223333444455556666777788889999aaaabbbbccccddddeeee0000',
        uniqueId: '0xaaaa...00-0',
        from: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
        to: address,
        value: 25.0,
        asset: 'UNI',
        category: 'erc20',
        timestamp: now.subtract(const Duration(days: 5)),
        type: TransactionType.received,
      ),
      // 보낸 LINK
      TransactionModel(
        hash: '0xbbbb222233334444555566667777888899990000aaaabbbbccccddddeeee1111',
        uniqueId: '0xbbbb...11-0',
        from: address,
        to: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
        value: 10.5,
        asset: 'LINK',
        category: 'erc20',
        timestamp: now.subtract(const Duration(days: 7)),
        type: TransactionType.sent,
      ),
      // 오래된 ETH 수신
      TransactionModel(
        hash: '0xcccc333344445555666677778888999900001111222233334444555566667777',
        uniqueId: '0xcccc...77-0',
        from: '0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae',
        to: address,
        value: 2.5,
        asset: 'ETH',
        category: 'external',
        timestamp: now.subtract(const Duration(days: 14)),
        type: TransactionType.received,
      ),
      // DAI Transfer
      TransactionModel(
        hash: '0xdddd444455556666777788889999000011112222333344445555666677778888',
        uniqueId: '0xdddd...88-0',
        from: address,
        to: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        value: 1000.0,
        asset: 'DAI',
        category: 'erc20',
        timestamp: now.subtract(const Duration(days: 21)),
        type: TransactionType.sent,
      ),
      // Contract Interaction
      TransactionModel(
        hash: '0xeeee555566667777888899990000111122223333444455556666777788889999',
        uniqueId: '0xeeee...99-0',
        from: address,
        to: '0x7a250d5630b4cf539739df2c5dacb4c659f2488d',
        value: 0.0,
        asset: 'ETH',
        category: 'internal',
        timestamp: now.subtract(const Duration(days: 30)),
        type: TransactionType.sent,
      ),
    ];
  }

  bool _shouldFail() {
    return DateTime.now().millisecondsSinceEpoch % 100 < (MockConfig.errorProbability * 100);
  }
}
