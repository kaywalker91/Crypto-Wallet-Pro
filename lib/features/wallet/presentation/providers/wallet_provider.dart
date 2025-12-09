import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../../../shared/services/auth_session_service.dart';
import '../../../../shared/services/pin_service.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/create_wallet.dart';
import '../../domain/usecases/delete_wallet.dart';
import '../../domain/usecases/generate_mnemonic.dart';
import '../../domain/usecases/get_stored_wallet.dart';
import '../../domain/usecases/import_wallet.dart';

/// Wallet creation step enum
enum WalletCreationStep {
  /// Initial step - choose create or import
  intro,

  /// Show generated mnemonic to user
  showMnemonic,

  /// User confirms mnemonic backup
  confirmMnemonic,

  /// Wallet creation complete
  complete,
}

/// Wallet state
class WalletState {
  final Wallet? wallet;
  final String? generatedMnemonic;
  final List<String> mnemonicWords;
  final bool isLoading;
  final String? error;
  final WalletCreationStep currentStep;
  final bool mnemonicBackupConfirmed;
  final bool isAuthenticated;

  const WalletState({
    this.wallet,
    this.generatedMnemonic,
    this.mnemonicWords = const [],
    this.isLoading = false,
    this.error,
    this.currentStep = WalletCreationStep.intro,
    this.mnemonicBackupConfirmed = false,
    this.isAuthenticated = false,
  });

  /// Check if wallet exists
  bool get hasWallet => wallet != null;

  /// Check if mnemonic is generated
  bool get hasMnemonic => generatedMnemonic != null && mnemonicWords.isNotEmpty;

  WalletState copyWith({
    Wallet? wallet,
    String? generatedMnemonic,
    List<String>? mnemonicWords,
    bool? isLoading,
    String? error,
    WalletCreationStep? currentStep,
    bool? mnemonicBackupConfirmed,
    bool? isAuthenticated,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      generatedMnemonic: generatedMnemonic ?? this.generatedMnemonic,
      mnemonicWords: mnemonicWords ?? this.mnemonicWords,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
      mnemonicBackupConfirmed:
          mnemonicBackupConfirmed ?? this.mnemonicBackupConfirmed,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Wallet notifier for managing wallet state
class WalletNotifier extends AsyncNotifier<WalletState> {
  late final GenerateMnemonic _generateMnemonic;
  late final CreateWallet _createWallet;
  late final ImportWallet _importWallet;
  late final GetStoredWallet _getStoredWallet;
  late final DeleteWallet _deleteWallet;
  late final BiometricService _biometricService;
  late final AuthSessionService _authSessionService;

  @override
  Future<WalletState> build() async {
    _generateMnemonic = ref.watch(generateMnemonicUseCaseProvider);
    _createWallet = ref.watch(createWalletUseCaseProvider);
    _importWallet = ref.watch(importWalletUseCaseProvider);
    _getStoredWallet = ref.watch(getStoredWalletUseCaseProvider);
    _deleteWallet = ref.watch(deleteWalletUseCaseProvider);
    _biometricService = ref.watch(biometricServiceProvider);
    _authSessionService = ref.watch(authSessionServiceProvider);

    final hasSession = await _authSessionService.hasValidSession();
    final result = await _getStoredWallet();
    return result.match(
      (failure) => WalletState(
        wallet: null,
        isLoading: false,
        error: failure.message,
        currentStep: WalletCreationStep.intro,
        isAuthenticated: hasSession,
      ),
      (wallet) => WalletState(
        wallet: wallet,
        isLoading: false,
        currentStep: wallet != null ? WalletCreationStep.complete : WalletCreationStep.intro,
        isAuthenticated: hasSession && wallet != null,
      ),
    );
  }

  WalletState _stateOrDefault() {
    return state.maybeWhen(
      data: (value) => value,
      orElse: () => const WalletState(),
    );
  }

  void _setState(WalletState newState) {
    state = AsyncData(newState);
  }

  /// Trigger biometric authentication before accessing secure storage.
  Future<bool> authenticate() async {
    final success = await _authSessionService.ensureAuthenticated();
    final current = _stateOrDefault();
    _setState(current.copyWith(isAuthenticated: success));
    return success;
  }

  /// Mark the current session as authenticated (used by PIN fallback).
  Future<void> markAuthenticated() async {
    await _authSessionService.markSessionValid();
    final current = _stateOrDefault();
    _setState(current.copyWith(isAuthenticated: true));
  }

  /// Generate new wallet with mnemonic (without persisting until confirmed)
  Future<void> generateNewWallet() async {
    final current = _stateOrDefault();
    _setState(current.copyWith(isLoading: true, error: null));

    try {
      final mnemonicResult = await _generateMnemonic();
      mnemonicResult.match(
        (failure) => _setState(current.copyWith(
              isLoading: false,
              error: failure.message,
            )),
        (mnemonic) {
          final words = mnemonic.split(' ');

          _setState(current.copyWith(
            isLoading: false,
            generatedMnemonic: mnemonic,
            mnemonicWords: words,
            currentStep: WalletCreationStep.showMnemonic,
          ));
        },
      );
    } catch (e) {
      _setState(
        current.copyWith(
          isLoading: false,
          error: 'Failed to generate wallet: $e',
        ),
      );
    }
  }

  /// Move to mnemonic confirmation step
  void proceedToConfirmation() {
    final current = _stateOrDefault();
    _setState(
      current.copyWith(
        currentStep: WalletCreationStep.confirmMnemonic,
      ),
    );
  }

  /// Confirm mnemonic backup and create wallet
  Future<void> confirmMnemonicBackup() async {
    final current = _stateOrDefault();
    final mnemonic = current.generatedMnemonic;
    if (mnemonic == null) {
      _setState(current.copyWith(error: 'Mnemonic missing. Start over.'));
      return;
    }

    _setState(current.copyWith(isLoading: true, error: null));

    final result = await _createWallet(mnemonic: mnemonic);
    result.match(
      (failure) => _setState(current.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (wallet) => _setState(WalletState(
        wallet: wallet,
        mnemonicBackupConfirmed: true,
        currentStep: WalletCreationStep.complete,
        isAuthenticated: current.isAuthenticated,
      )),
    );
  }

  /// Import wallet from mnemonic and persist
  Future<void> importWallet(String mnemonic) async {
    final current = _stateOrDefault();
    _setState(current.copyWith(isLoading: true, error: null));

    final result = await _importWallet(mnemonic);
    result.match(
      (failure) => _setState(current.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (wallet) => _setState(current.copyWith(
        isLoading: false,
        wallet: wallet,
        currentStep: WalletCreationStep.complete,
        error: null,
      )),
    );
  }

  /// Validate mnemonic words
  bool validateMnemonic(List<String> words) {
    final mnemonic = words.join(' ').trim();
    return bip39.validateMnemonic(mnemonic);
  }

  /// Delete wallet data (mnemonic + cached metadata)
  Future<void> deleteWallet() async {
    final current = _stateOrDefault();
    _setState(current.copyWith(isLoading: true, error: null));

    final result = await _deleteWallet();
    result.match(
      (failure) => _setState(current.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (_) => _setState(const WalletState()),
    );
  }

  /// Go back to previous step
  void goBack() {
    final current = _stateOrDefault();
    switch (current.currentStep) {
      case WalletCreationStep.showMnemonic:
        _setState(
          current.copyWith(
            currentStep: WalletCreationStep.intro,
            generatedMnemonic: null,
            mnemonicWords: const [],
          ),
        );
        break;
      case WalletCreationStep.confirmMnemonic:
        _setState(
          current.copyWith(
            currentStep: WalletCreationStep.showMnemonic,
          ),
        );
        break;
      default:
        break;
    }
  }

  /// Reset wallet state
  void reset() {
    _setState(const WalletState());
  }

  /// Clear error
  void clearError() {
    final current = _stateOrDefault();
    _setState(current.copyWith(error: null));
  }
}

/// Wallet provider
final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

WalletState _unwrapWalletState(AsyncValue<WalletState> asyncState) =>
    asyncState.maybeWhen(
      data: (value) => value,
      orElse: () => const WalletState(),
    );

/// Convenience provider to expose a concrete WalletState while respecting async loading.
final walletViewProvider = Provider<WalletState>((ref) {
  final asyncState = ref.watch(walletProvider);
  final baseState = _unwrapWalletState(asyncState);
  if (asyncState.isLoading) {
    return baseState.copyWith(isLoading: true);
  }
  return baseState;
});

/// Provider to check if user has completed wallet setup
final hasWalletProvider = Provider<bool>((ref) {
  final walletState = _unwrapWalletState(ref.watch(walletProvider));
  return walletState.hasWallet;
});

/// Provider for current wallet creation step
final walletCreationStepProvider = Provider<WalletCreationStep>((ref) {
  final walletState = _unwrapWalletState(ref.watch(walletProvider));
  return walletState.currentStep;
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(LocalAuthentication());
});

final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final biometric = ref.watch(biometricServiceProvider);
  final settings = ref.watch(settingsProvider).settings;
  final authEnabled = settings.biometricEnabled || settings.pinEnabled;
  return AuthSessionService(
    storage,
    biometric,
    authEnabled: authEnabled,
  );
});

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return PinService(storage);
});

/// Lazy check for whether a PIN is set.
final hasPinProvider = FutureProvider<bool>((ref) async {
  final pinService = ref.watch(pinServiceProvider);
  return pinService.hasPin();
});
final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final authSession = ref.watch(authSessionServiceProvider);
  return WalletLocalDataSourceImpl(storage, authSession);
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final local = ref.watch(walletLocalDataSourceProvider);
  return WalletRepositoryImpl(local);
});

final createWalletUseCaseProvider =
    Provider<CreateWallet>((ref) => CreateWallet(ref.watch(walletRepositoryProvider)));

final generateMnemonicUseCaseProvider =
    Provider<GenerateMnemonic>((ref) => GenerateMnemonic(ref.watch(walletRepositoryProvider)));

final importWalletUseCaseProvider =
    Provider<ImportWallet>((ref) => ImportWallet(ref.watch(walletRepositoryProvider)));

final getStoredWalletUseCaseProvider =
    Provider<GetStoredWallet>((ref) => GetStoredWallet(ref.watch(walletRepositoryProvider)));

final deleteWalletUseCaseProvider =
    Provider<DeleteWallet>((ref) => DeleteWallet(ref.watch(walletRepositoryProvider)));
