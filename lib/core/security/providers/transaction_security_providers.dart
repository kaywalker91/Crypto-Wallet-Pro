import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_security.dart';
import '../services/device_integrity_service.dart';
import '../services/overlay_protection_service.dart';
import '../services/screen_recording_detection_service.dart';
import '../services/screenshot_detection_service.dart';
import '../services/secure_transaction_signer.dart';
import '../services/tamper_detection_service.dart';

/// Phase 10: Transaction Security Providers

// ============================================================================
// Service Providers
// ============================================================================

/// Overlay Protection Service Provider
final overlayProtectionServiceProvider = Provider<OverlayProtectionService>(
  (ref) => OverlayProtectionService(),
);

/// Tamper Detection Service Provider
final tamperDetectionServiceProvider = Provider<TamperDetectionService>(
  (ref) => TamperDetectionService(),
);

/// Screenshot Detection Service Provider
final screenshotDetectionServiceProvider = Provider<ScreenshotDetectionService>(
  (ref) => ScreenshotDetectionService(),
);

/// Screen Recording Detection Service Provider
final screenRecordingDetectionServiceProvider =
    Provider<ScreenRecordingDetectionService>(
  (ref) => ScreenRecordingDetectionService(),
);

/// Device Integrity Service Provider (재사용)
final deviceIntegrityServiceProvider = Provider<DeviceIntegrityService>(
  (ref) => DeviceIntegrityService(),
);

// ============================================================================
// Transaction Security Config Provider
// ============================================================================

/// Transaction Security Config State Notifier
class TransactionSecurityConfigNotifier
    extends StateNotifier<TransactionSecurityConfig> {
  TransactionSecurityConfigNotifier()
      : super(const TransactionSecurityConfig());

  /// 설정 업데이트
  void updateConfig(TransactionSecurityConfig newConfig) {
    state = newConfig;
  }

  /// Strict 모드로 전환
  void enableStrictMode() {
    state = const TransactionSecurityConfig.strict();
  }

  /// Relaxed 모드로 전환
  void enableRelaxedMode() {
    state = const TransactionSecurityConfig.relaxed();
  }

  /// 개별 설정 토글
  void toggleOverlayProtection() {
    state = state.copyWith(
      overlayProtectionEnabled: !state.overlayProtectionEnabled,
    );
  }

  void toggleRecordingDetection() {
    state = state.copyWith(
      recordingDetectionEnabled: !state.recordingDetectionEnabled,
    );
  }

  void toggleScreenshotDetection() {
    state = state.copyWith(
      screenshotDetectionEnabled: !state.screenshotDetectionEnabled,
    );
  }

  void toggleBlockCompromisedDevices() {
    state = state.copyWith(
      blockCompromisedDevices: !state.blockCompromisedDevices,
    );
  }

  void toggleRequireBiometrics() {
    state = state.copyWith(
      requireBiometrics: !state.requireBiometrics,
    );
  }

  void setMaxRiskScore(double score) {
    state = state.copyWith(maxAllowedRiskScore: score);
  }
}

/// Transaction Security Config Provider
final transactionSecurityConfigProvider = StateNotifierProvider<
    TransactionSecurityConfigNotifier, TransactionSecurityConfig>(
  (ref) => TransactionSecurityConfigNotifier(),
);

// ============================================================================
// Secure Transaction Signer Provider
// ============================================================================

/// Secure Transaction Signer Provider
final secureTransactionSignerProvider = Provider<SecureTransactionSigner>(
  (ref) {
    final config = ref.watch(transactionSecurityConfigProvider);
    final deviceIntegrityService = ref.read(deviceIntegrityServiceProvider);
    final overlayProtectionService = ref.read(overlayProtectionServiceProvider);
    final tamperDetectionService = ref.read(tamperDetectionServiceProvider);
    final recordingDetectionService =
        ref.read(screenRecordingDetectionServiceProvider);
    final screenshotDetectionService =
        ref.read(screenshotDetectionServiceProvider);

    return SecureTransactionSigner(
      config: config,
      deviceIntegrityService: deviceIntegrityService,
      overlayProtectionService: overlayProtectionService,
      tamperDetectionService: tamperDetectionService,
      recordingDetectionService: recordingDetectionService,
      screenshotDetectionService: screenshotDetectionService,
    );
  },
);

// ============================================================================
// Transaction Security State Provider
// ============================================================================

/// Transaction Security State
class TransactionSecurityState {
  final TransactionSecurityContext? currentContext;
  final bool isPreparingContext;
  final String? error;

  const TransactionSecurityState({
    this.currentContext,
    this.isPreparingContext = false,
    this.error,
  });

  TransactionSecurityState copyWith({
    TransactionSecurityContext? currentContext,
    bool? isPreparingContext,
    String? error,
  }) {
    return TransactionSecurityState(
      currentContext: currentContext ?? this.currentContext,
      isPreparingContext: isPreparingContext ?? this.isPreparingContext,
      error: error,
    );
  }

  bool get isSafeForSigning =>
      currentContext?.isSafeForSigning ?? false;

  double get riskScore => currentContext?.riskScore ?? 1.0;

  List<SecurityCheckResult> get failedChecks =>
      currentContext?.failedChecks ?? [];
}

/// Transaction Security State Notifier
class TransactionSecurityStateNotifier
    extends StateNotifier<TransactionSecurityState> {
  final SecureTransactionSigner _signer;

  TransactionSecurityStateNotifier(this._signer)
      : super(const TransactionSecurityState());

  /// 보안 컨텍스트 준비
  Future<void> prepareSecurityContext() async {
    state = state.copyWith(isPreparingContext: true, error: null);

    try {
      final context = await _signer.prepareSecureContext();
      state = state.copyWith(
        currentContext: context,
        isPreparingContext: false,
      );
    } catch (e) {
      state = state.copyWith(
        isPreparingContext: false,
        error: e.toString(),
      );
    }
  }

  /// 트랜잭션 서명
  Future<SignedTransaction> signTransaction(
    TransactionData transaction,
    String pin,
  ) async {
    try {
      final signed = await _signer.signTransaction(transaction, pin);
      return signed;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 상태 초기화
  void reset() {
    state = const TransactionSecurityState();
  }
}

/// Transaction Security State Provider
final transactionSecurityStateProvider = StateNotifierProvider<
    TransactionSecurityStateNotifier, TransactionSecurityState>(
  (ref) {
    final signer = ref.watch(secureTransactionSignerProvider);
    return TransactionSecurityStateNotifier(signer);
  },
);

// ============================================================================
// Overlay Status Provider
// ============================================================================

/// Overlay Status Provider (FutureProvider)
final overlayStatusProvider = FutureProvider<OverlayStatus>((ref) async {
  final service = ref.read(overlayProtectionServiceProvider);
  return await service.checkOverlayStatus();
});

// ============================================================================
// Screen Recording Status Provider
// ============================================================================

/// Screen Recording Status Provider (FutureProvider)
final screenRecordingStatusProvider =
    FutureProvider<ScreenRecordingStatus>((ref) async {
  final service = ref.read(screenRecordingDetectionServiceProvider);
  return await service.isRecordingActive();
});

// ============================================================================
// Tamper Detection Result Provider
// ============================================================================

/// Tamper Detection Result Provider (FutureProvider)
final tamperDetectionResultProvider =
    FutureProvider<TamperDetectionResult>((ref) async {
  final service = ref.read(tamperDetectionServiceProvider);
  return await service.verifyAppIntegrity();
});
