import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/advanced_root_detection_service.dart';
import '../services/secure_enclave_service.dart';
import '../services/security_attestation_service.dart';
import '../hsm/hsm_manager.dart';
import '../hsm/hsm_capability.dart';

/// Advanced Root Detection 서비스 프로바이더
final advancedRootDetectionProvider = Provider<AdvancedRootDetectionService>(
  (ref) => AdvancedRootDetectionService(),
);

/// Secure Enclave 서비스 프로바이더
final secureEnclaveServiceProvider = Provider<SecureEnclaveService>(
  (ref) => SecureEnclaveService(),
);

/// HSM 매니저 프로바이더
final hsmManagerProvider = Provider<HsmManager>(
  (ref) => HsmManager(),
);

/// Security Attestation 서비스 프로바이더
final securityAttestationProvider = Provider<SecurityAttestationService>(
  (ref) => SecurityAttestationService(),
);

/// Hardware Security 종합 상태 프로바이더
///
/// 하드웨어 보안 기능의 전반적인 상태를 제공합니다.
final hardwareSecurityStateProvider =
    FutureProvider<HardwareSecurityState>((ref) async {
  final hsmManager = ref.watch(hsmManagerProvider);
  final secureEnclave = ref.watch(secureEnclaveServiceProvider);
  final attestation = ref.watch(securityAttestationProvider);
  final rootDetection = ref.watch(advancedRootDetectionProvider);

  // HSM 초기화
  await hsmManager.initialize();

  // 각 서비스 상태 확인
  final hsmInfo = await hsmManager.getHsmInfo();
  final isEnclaveAvailable = await secureEnclave.isAvailable();
  final attestationResult = await attestation.performAttestation();
  final rootScanResult = await rootDetection.performQuickScan();

  return HardwareSecurityState(
    hsmInfo: hsmInfo,
    isSecureEnclaveAvailable: isEnclaveAvailable,
    attestationResult: attestationResult,
    rootDetectionResult: rootScanResult,
  );
});

/// Hardware Security 종합 상태
class HardwareSecurityState {
  /// HSM 정보
  final HsmInfo hsmInfo;

  /// Secure Enclave 사용 가능 여부
  final bool isSecureEnclaveAvailable;

  /// 최근 증명 결과
  final AttestationResult attestationResult;

  /// 최근 루팅 탐지 결과
  final RootDetectionResult rootDetectionResult;

  const HardwareSecurityState({
    required this.hsmInfo,
    required this.isSecureEnclaveAvailable,
    required this.attestationResult,
    required this.rootDetectionResult,
  });

  /// 전반적으로 안전한 환경인지 확인
  bool get isSecure =>
      hsmInfo.isAvailable &&
      attestationResult.isSecure &&
      !rootDetectionResult.isCompromised;

  /// 하드웨어 보안 기능이 완전히 사용 가능한지 확인
  bool get isFullySecure =>
      isSecure &&
      hsmInfo.isHardwareBacked &&
      isSecureEnclaveAvailable;

  /// 위험한 환경인지 확인
  bool get isCompromised =>
      attestationResult.isCompromised ||
      rootDetectionResult.isCompromised;

  /// 보안 수준 점수 (0.0 ~ 1.0)
  ///
  /// - 1.0: 완벽한 보안 (하드웨어 HSM + Enclave + 안전한 환경)
  /// - 0.7~1.0: 우수 (소프트웨어 폴백 사용)
  /// - 0.3~0.7: 보통 (일부 취약점 존재)
  /// - 0.0~0.3: 위험 (루팅/탈옥 또는 손상된 환경)
  double get securityScore {
    double score = 0.5; // 기본 점수

    // HSM 하드웨어 지원 (+0.2)
    if (hsmInfo.isHardwareBacked) {
      score += 0.2;
    }

    // Secure Enclave 사용 가능 (+0.1)
    if (isSecureEnclaveAvailable) {
      score += 0.1;
    }

    // 증명 결과 (±0.2)
    if (attestationResult.isSecure) {
      score += 0.2;
    } else if (attestationResult.isCompromised) {
      score -= 0.2;
    }

    // 루팅 탐지 결과 (±0.3)
    if (!rootDetectionResult.isCompromised) {
      score += 0.2;
    } else {
      score -= rootDetectionResult.confidenceScore * 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'HardwareSecurityState('
        'secure: $isSecure, '
        'score: ${securityScore.toStringAsFixed(2)}, '
        'hsm: ${hsmInfo.name}'
        ')';
  }
}
