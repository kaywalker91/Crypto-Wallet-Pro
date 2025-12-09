import 'package:crypto_wallet_pro/core/error/failures.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/entities/wallet.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/usecases/create_wallet.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/usecases/delete_wallet.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/usecases/generate_mnemonic.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/usecases/get_stored_wallet.dart';
import 'package:crypto_wallet_pro/features/wallet/domain/usecases/import_wallet.dart';
import 'package:crypto_wallet_pro/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:crypto_wallet_pro/shared/providers/storage_providers.dart';
import 'package:crypto_wallet_pro/shared/services/auth_session_service.dart';
import 'package:crypto_wallet_pro/shared/services/biometric_service.dart';
import 'package:crypto_wallet_pro/shared/services/secure_storage_service.dart';
import 'package:crypto_wallet_pro/shared/services/pin_service.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({
    required this.generatedMnemonic,
    this.storedWallet,
    this.importedWallet,
  });

  final String generatedMnemonic;
  Wallet? storedWallet;
  Wallet? importedWallet;
  int deleteCalls = 0;

  @override
  Future<Either<Failure, void>> deleteWallet() async {
    deleteCalls += 1;
    storedWallet = null;
    return right(null);
  }

  @override
  Future<Either<Failure, Wallet>> createWallet({String? mnemonic}) async {
    return right(importedWallet ?? storedWallet ?? _dummyWallet());
  }

  @override
  Future<Either<Failure, Wallet?>> getStoredWallet() async {
    return right(storedWallet);
  }

  @override
  Future<Either<Failure, String>> generateMnemonic() async {
    return right(generatedMnemonic);
  }

  @override
  Future<Either<Failure, Wallet>> importWallet(String mnemonic) async {
    return right(importedWallet ?? _dummyWallet());
  }

  @override
  Future<Either<Failure, String>> getStoredMnemonic() async {
    return left(const StorageFailure('not implemented'));
  }

  Wallet _dummyWallet() => Wallet(
        address: '0x0001',
        createdAt: DateTime.utc(2024, 1, 1),
      );
}

class FakeAuthSessionService implements AuthSessionService {
  int ensureCount = 0;

  @override
  bool get authEnabled => true;

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> ensureAuthenticated({String reason = '지갑 접근을 위해 인증이 필요합니다.'}) async {
    ensureCount += 1;
    return true;
  }

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> markSessionValid() async {
    ensureCount += 1;
  }
}

class FakeBiometricService implements BiometricService {
  @override
  Future<bool> authenticate({String reason = 'Authenticate to access your wallet'}) async {
    return true;
  }

  @override
  Future<bool> canCheck() async => true;

  @override
  void extendSession(DateTime validUntil) {}

  @override
  bool get hasValidSession => true;

  @override
  Future<bool> ensureAuthenticated({String reason = 'Authenticate to access your wallet'}) async {
    return true;
  }
}

class FakeSecureStorage implements SecureStorageService {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write({required String key, required String value, bool isSensitive = true}) async {}
}

class FakePinService extends PinService {
  FakePinService() : super(FakeSecureStorage());
}

void main() {
  final wallet = Wallet(
    address: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
    createdAt: DateTime.utc(2024, 1, 1),
  );

  ProviderContainer _buildContainer(FakeWalletRepository repository,
      {FakeAuthSessionService? authSessionService}) {
    final authSession = authSessionService ?? FakeAuthSessionService();

    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repository),
        createWalletUseCaseProvider.overrideWithValue(CreateWallet(repository)),
        generateMnemonicUseCaseProvider
            .overrideWithValue(GenerateMnemonic(repository)),
        importWalletUseCaseProvider.overrideWithValue(ImportWallet(repository)),
        getStoredWalletUseCaseProvider
            .overrideWithValue(GetStoredWallet(repository)),
        deleteWalletUseCaseProvider.overrideWithValue(DeleteWallet(repository)),
        authSessionServiceProvider.overrideWithValue(authSession),
        biometricServiceProvider.overrideWithValue(FakeBiometricService()),
        pinServiceProvider.overrideWithValue(FakePinService()),
        secureStorageServiceProvider.overrideWithValue(FakeSecureStorage()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('초기 로드 시 저장된 지갑이 있으면 complete 단계로 진입한다', () async {
    final repository = FakeWalletRepository(
      generatedMnemonic: 'foo bar',
      storedWallet: wallet,
    );
    final container = _buildContainer(repository);

    final state = await container.read(walletProvider.future);

    expect(state.wallet, wallet);
    expect(state.currentStep, WalletCreationStep.complete);
    expect(state.isLoading, isFalse);
  });

  test('생체 인증 성공 시 인증 플래그가 설정된다', () async {
    final repository = FakeWalletRepository(
      generatedMnemonic: 'foo bar baz qux quux corge grault garply waldo fred plugh xyzzy',
      storedWallet: wallet,
    );
    final authSession = FakeAuthSessionService();
    final container = _buildContainer(repository, authSessionService: authSession);

    await container.read(walletProvider.notifier).authenticate();
    final current = container.read(walletViewProvider);

    expect(current.isAuthenticated, isTrue);
    expect(authSession.ensureCount, greaterThan(0));
  });

  test('니모닉 생성 -> 확인 완료 시 complete 상태가 된다', () async {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    final repository = FakeWalletRepository(
      generatedMnemonic: mnemonic,
      importedWallet: wallet,
    );
    final container = _buildContainer(repository);

    await container.read(walletProvider.notifier).generateNewWallet();
    var state = container.read(walletViewProvider);
    expect(state.generatedMnemonic, mnemonic);
    expect(state.currentStep, WalletCreationStep.showMnemonic);

    await container.read(walletProvider.notifier).confirmMnemonicBackup();
    state = container.read(walletViewProvider);
    expect(state.wallet, isNotNull);
    expect(state.currentStep, WalletCreationStep.complete);
    expect(state.mnemonicWords, isEmpty);
  });
}
