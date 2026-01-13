import '../../../wallet/domain/entities/wallet.dart';

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
/// 
/// 지갑의 현재 상태를 나타내는 불변 클래스입니다.
/// - 생성, 가져오기, 니모닉 확인 등의 단계별 상태 관리
/// - 인증 상태 추적
/// - 에러 및 로딩 상태 관리
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

  /// Check if wallet creation is in progress
  bool get isCreating => 
      currentStep == WalletCreationStep.showMnemonic || 
      currentStep == WalletCreationStep.confirmMnemonic;

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

  @override
  String toString() {
    return 'WalletState('
        'hasWallet: $hasWallet, '
        'step: $currentStep, '
        'isLoading: $isLoading, '
        'isAuthenticated: $isAuthenticated'
        ')';
  }
}
