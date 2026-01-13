import 'package:crypto_wallet_pro/core/error/failures.dart';
import 'package:crypto_wallet_pro/features/wallet/data/datasources/wallet_local_datasource.dart';
import 'package:crypto_wallet_pro/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/entities/wallet.dart';
import 'package:crypto_wallet_pro/shared/services/auth_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/credentials.dart' show EthPrivateKey;

/// Mock AuthSessionService for testing
/// 항상 인증 성공을 반환
class MockAuthSessionService implements AuthSessionService {
  @override
  bool get authEnabled => true;

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<bool> ensureAuthenticated({String reason = ''}) async => true;

  @override
  Future<void> markSessionValid() async {}

  @override
  Future<void> clearSession() async {}
}

/// Mock AuthSessionService that always fails authentication
class _MockAuthSessionFailure implements AuthSessionService {
  @override
  bool get authEnabled => true;

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<bool> ensureAuthenticated({String reason = ''}) async => false;

  @override
  Future<void> markSessionValid() async {}

  @override
  Future<void> clearSession() async {}
}

class FakeWalletLocalDataSource implements WalletLocalDataSource {
  FakeWalletLocalDataSource({
    required this.generatedMnemonic,
    required this.wallet,
  });

  final String generatedMnemonic;
  final Wallet wallet;

  String? savedMnemonic;
  Wallet? cachedWallet;
  Object? throwable;

  @override
  Future<void> cacheWallet(Wallet wallet) async {
    if (throwable != null) throw throwable!;
    cachedWallet = wallet;
  }

  @override
  Future<void> clearAll() async {
    savedMnemonic = null;
    cachedWallet = null;
  }

  @override
  Future<void> deleteMnemonic() async {
    savedMnemonic = null;
  }

  @override
  Future<EthPrivateKey> derivePrivateKey(String mnemonic) async {
    return EthPrivateKey.fromHex('0x${'1'.padLeft(64, '0')}');
  }

  @override
  Future<Wallet> deriveWallet(String mnemonic) async {
    if (throwable != null) throw throwable!;
    return wallet;
  }

  @override
  Future<String> generateMnemonic() async {
    if (throwable != null) throw throwable!;
    return generatedMnemonic;
  }

  @override
  Future<String?> getMnemonic() async {
    if (throwable != null) throw throwable!;
    return savedMnemonic;
  }

  @override
  Future<Wallet?> readCachedWallet() async {
    if (throwable != null) throw throwable!;
    return cachedWallet;
  }

  @override
  Future<void> saveMnemonic(String mnemonic) async {
    if (throwable != null) throw throwable!;
    savedMnemonic = mnemonic;
  }

  @override
  Future<String?> retrievePrivateKey() async {
    if (throwable != null) throw throwable!;
    return '0x${'1'.padLeft(64, '0')}';
  }
}

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  final wallet = Wallet(
    address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
    createdAt: DateTime.utc(2024, 1, 1),
  );

  test('createWallet uses provided mnemonic and caches wallet', () async {
    final dataSource = FakeWalletLocalDataSource(
      generatedMnemonic: 'random phrase',
      wallet: wallet,
    );
    final authSession = MockAuthSessionService();
    final repository = WalletRepositoryImpl(dataSource, authSession);

    final result = await repository.createWallet(mnemonic: mnemonic);

    expect(result.isRight(), isTrue);
    expect(dataSource.savedMnemonic, mnemonic);
    expect(dataSource.cachedWallet, wallet);
  });

  test('getStoredMnemonic surfaces storage failure when missing', () async {
    final dataSource = FakeWalletLocalDataSource(
      generatedMnemonic: mnemonic,
      wallet: wallet,
    );
    final authSession = MockAuthSessionService();
    final repository = WalletRepositoryImpl(dataSource, authSession);

    final result = await repository.getStoredMnemonic();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<StorageFailure>()),
      (_) => fail('Expected storage failure'),
    );
  });

  test('errors are mapped to Failure when data source throws', () async {
    final dataSource = FakeWalletLocalDataSource(
      generatedMnemonic: mnemonic,
      wallet: wallet,
    )..throwable = Exception('boom');
    final authSession = MockAuthSessionService();
    final repository = WalletRepositoryImpl(dataSource, authSession);

    final result = await repository.createWallet();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure.message, contains('boom')),
      (_) => fail('Expected failure'),
    );
  });

  test('getPrivateKey returns AuthenticationFailure when not authenticated', () async {
    final dataSource = FakeWalletLocalDataSource(
      generatedMnemonic: mnemonic,
      wallet: wallet,
    );
    // 인증 실패 Mock
    final authSession = _MockAuthSessionFailure();
    final repository = WalletRepositoryImpl(dataSource, authSession);

    final result = await repository.getPrivateKey();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<AuthenticationFailure>()),
      (_) => fail('Expected authentication failure'),
    );
  });
}
