import '../../../../core/constants/mock_config.dart';
import 'balance_remote_datasource.dart';

/// 목업 잔액 데이터 소스
///
/// API 호출 없이 기능 흐름을 테스트할 수 있도록 목업 데이터 제공
class MockBalanceDataSource implements BalanceRemoteDataSource {
  MockBalanceDataSource();

  @override
  Future<BigInt> getEthBalance(String address) async {
    // 실제 API 응답 시간 시뮬레이션
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Network error');
    }

    // 목업 ETH 잔액 (1.5234 ETH in Wei)
    return BigInt.from(1.5234 * 1e18);
  }

  @override
  Future<BigInt> getERC20Balance(String tokenAddress, String walletAddress) async {
    await Future.delayed(Duration(milliseconds: MockConfig.mockDelayMs ~/ 2));

    if (MockConfig.simulateErrors && _shouldFail()) {
      throw Exception('Mock: Token balance fetch failed');
    }

    // 토큰 주소에 따른 목업 잔액
    return _getMockTokenBalance(tokenAddress);
  }

  BigInt _getMockTokenBalance(String tokenAddress) {
    final address = tokenAddress.toLowerCase();

    // USDT (6 decimals)
    if (address == '0xdac17f958d2ee523a2206206994597c13d831ec7') {
      return BigInt.from(2500 * 1e6); // 2,500 USDT
    }
    // UNI (18 decimals)
    if (address == '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984') {
      return BigInt.from(45.75 * 1e18); // 45.75 UNI
    }
    // LINK (18 decimals)
    if (address == '0x514910771af9ca656af840dff83e8264ecf986ca') {
      return BigInt.from(120.5 * 1e18); // 120.5 LINK
    }
    // USDC (6 decimals)
    if (address == '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48') {
      return BigInt.from(5000 * 1e6); // 5,000 USDC
    }
    // DAI (18 decimals)
    if (address == '0x6b175474e89094c44da98b954eedeac495271d0f') {
      return BigInt.from(1234.56 * 1e18); // 1,234.56 DAI
    }

    // 알 수 없는 토큰 - 기본 잔액
    return BigInt.from(100 * 1e18);
  }

  bool _shouldFail() {
    return DateTime.now().millisecondsSinceEpoch % 100 < (MockConfig.errorProbability * 100);
  }
}
