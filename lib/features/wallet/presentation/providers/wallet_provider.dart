import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 분리된 파일들 import
import 'wallet_state.dart';
import 'wallet_service_providers.dart';
import 'wallet_usecase_providers.dart';

// Re-export for backward compatibility
export 'wallet_state.dart';
export 'wallet_service_providers.dart';
export 'wallet_usecase_providers.dart';

// ============================================================================
// Wallet Notifier
// ============================================================================

/// Wallet notifier for managing wallet state
/// 
/// 지갑 생성, 가져오기, 삭제 등의 상태를 관리합니다.
/// Use Case 패턴을 사용하여 비즈니스 로직을 Domain Layer에 위임합니다.
class WalletNotifier extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async {
    final generateMnemonic = ref.watch(generateMnemonicUseCaseProvider);
    final getStoredWallet = ref.watch(getStoredWalletUseCaseProvider);
    final authSessionService = ref.watch(authSessionServiceProvider);

    final hasSession = await authSessionService.hasValidSession();
    final result = await getStoredWallet();
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
    final authSessionService = ref.read(authSessionServiceProvider);
    final success = await authSessionService.ensureAuthenticated();
    final current = _stateOrDefault();
    _setState(current.copyWith(isAuthenticated: success));
    return success;
  }

  /// Mark the current session as authenticated (used by PIN fallback).
  Future<void> markAuthenticated() async {
    final authSessionService = ref.read(authSessionServiceProvider);
    await authSessionService.markSessionValid();
    final current = _stateOrDefault();
    _setState(current.copyWith(isAuthenticated: true));
  }

  /// Generate new wallet with mnemonic (without persisting until confirmed)
  Future<void> generateNewWallet() async {
    final current = _stateOrDefault();
    _setState(current.copyWith(isLoading: true, error: null));

    try {
      final generateMnemonic = ref.read(generateMnemonicUseCaseProvider);
      final mnemonicResult = await generateMnemonic();
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

    final createWallet = ref.read(createWalletUseCaseProvider);
    final result = await createWallet(mnemonic: mnemonic);
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

    final importWalletUseCase = ref.read(importWalletUseCaseProvider);
    final result = await importWalletUseCase(mnemonic);
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

    final deleteWalletUseCase = ref.read(deleteWalletUseCaseProvider);
    final result = await deleteWalletUseCase();
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

// ============================================================================
// Main Providers
// ============================================================================

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
