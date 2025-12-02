import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wallet.dart';

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

  const WalletState({
    this.wallet,
    this.generatedMnemonic,
    this.mnemonicWords = const [],
    this.isLoading = false,
    this.error,
    this.currentStep = WalletCreationStep.intro,
    this.mnemonicBackupConfirmed = false,
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
    );
  }
}

/// Wallet notifier for managing wallet state
class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState()) {
    _checkExistingWallet();
  }

  /// Check if wallet already exists (Mock: always false for now)
  Future<void> _checkExistingWallet() async {
    state = state.copyWith(isLoading: true);

    // Simulate checking storage
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: No existing wallet
    state = state.copyWith(
      isLoading: false,
      wallet: null,
    );
  }

  /// Generate new wallet with mnemonic (Mock)
  Future<void> generateNewWallet() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate mnemonic generation delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock mnemonic generation
      final mnemonic = MockWallet.mockMnemonic;
      final words = mnemonic.split(' ');

      state = state.copyWith(
        isLoading: false,
        generatedMnemonic: mnemonic,
        mnemonicWords: words,
        currentStep: WalletCreationStep.showMnemonic,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate wallet: $e',
      );
    }
  }

  /// Move to mnemonic confirmation step
  void proceedToConfirmation() {
    state = state.copyWith(
      currentStep: WalletCreationStep.confirmMnemonic,
    );
  }

  /// Confirm mnemonic backup and create wallet
  Future<void> confirmMnemonicBackup() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate wallet creation delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock wallet creation
      final wallet = MockWallet.mock;

      state = state.copyWith(
        isLoading: false,
        wallet: wallet,
        mnemonicBackupConfirmed: true,
        currentStep: WalletCreationStep.complete,
        // Clear mnemonic from memory after wallet is created
        generatedMnemonic: null,
        mnemonicWords: const [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create wallet: $e',
      );
    }
  }

  /// Import wallet from mnemonic (Mock)
  Future<void> importWallet(String mnemonic) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate mnemonic format
      final words = mnemonic.trim().split(RegExp(r'\s+'));
      if (words.length != 12 && words.length != 24) {
        throw Exception('Invalid mnemonic: must be 12 or 24 words');
      }

      // Simulate import delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock wallet import
      final wallet = Wallet(
        address: '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(40, '0')}',
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        wallet: wallet,
        currentStep: WalletCreationStep.complete,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import wallet: $e',
      );
    }
  }

  /// Validate mnemonic words
  bool validateMnemonic(List<String> words) {
    if (words.length != 12 && words.length != 24) {
      return false;
    }

    // Mock validation: just check if all words are non-empty
    return words.every((word) => word.trim().isNotEmpty);
  }

  /// Go back to previous step
  void goBack() {
    switch (state.currentStep) {
      case WalletCreationStep.showMnemonic:
        state = state.copyWith(
          currentStep: WalletCreationStep.intro,
          generatedMnemonic: null,
          mnemonicWords: const [],
        );
        break;
      case WalletCreationStep.confirmMnemonic:
        state = state.copyWith(
          currentStep: WalletCreationStep.showMnemonic,
        );
        break;
      default:
        break;
    }
  }

  /// Reset wallet state
  void reset() {
    state = const WalletState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Wallet provider
final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});

/// Provider to check if user has completed wallet setup
final hasWalletProvider = Provider<bool>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.hasWallet;
});

/// Provider for current wallet creation step
final walletCreationStepProvider = Provider<WalletCreationStep>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.currentStep;
});
