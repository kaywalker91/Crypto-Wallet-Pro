import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/credentials.dart';

import 'package:crypto_wallet_pro/features/wallet/data/datasources/wallet_local_datasource.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:crypto_wallet_pro/shared/services/auth_session_service.dart';

class InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool isSensitive = true,
  }) async {
    _store[key] = value;
  }
}

class FakeAuthSessionService implements AuthSessionService {
  @override
  bool get authEnabled => true;

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> ensureAuthenticated({String reason = '지갑 접근을 위해 인증이 필요합니다.'}) async {
    return true;
  }

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> markSessionValid() async {}
}

void main() {
  late InMemorySecureStorage storage;
  late WalletLocalDataSource dataSource;
  late FakeAuthSessionService authSession;

  setUp(() {
    storage = InMemorySecureStorage();
    authSession = FakeAuthSessionService();
    dataSource = WalletLocalDataSourceImpl(storage, authSession);
  });

  test('generateMnemonic returns valid 12-word phrase', () async {
    final mnemonic = await dataSource.generateMnemonic();

    expect(mnemonic.split(' ').length, 12);
    expect(bip39.validateMnemonic(mnemonic), isTrue);
  });

  test('deriveWallet is deterministic for the same mnemonic', () async {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    final walletA = await dataSource.deriveWallet(mnemonic);
    final walletB = await dataSource.deriveWallet(mnemonic);

    expect(walletA.address, walletB.address);
  });

  test('derivePrivateKey matches derived wallet address', () async {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    final key = await dataSource.derivePrivateKey(mnemonic);
    final wallet = await dataSource.deriveWallet(mnemonic);
    final address = await key.extractAddress();

    expect(address.hexEip55, wallet.address);
  });

  test('save/read/clear mnemonic flow works', () async {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    await dataSource.saveMnemonic(mnemonic);
    expect(await dataSource.getMnemonic(), mnemonic);

    await dataSource.cacheWallet(await dataSource.deriveWallet(mnemonic));
    final cachedWallet = await dataSource.readCachedWallet();
    expect(cachedWallet?.address, isNotEmpty);

    await dataSource.clearAll();
    expect(await dataSource.getMnemonic(), isNull);
    expect(await dataSource.readCachedWallet(), isNull);
  });
}
