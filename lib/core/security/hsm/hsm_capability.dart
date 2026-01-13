import 'package:equatable/equatable.dart';

/// HSM(Hardware Security Module) 기능
///
/// 하드웨어 보안 모듈이 지원하는 암호화 기능
enum HsmCapability {
  /// 키 생성
  keyGeneration,

  /// 서명 생성
  signing,

  /// 서명 검증
  verification,

  /// 암호화
  encryption,

  /// 복호화
  decryption,

  /// 키 내보내기 (보안 백업)
  keyExport,

  /// 키 가져오기
  keyImport,

  /// 생체 인증 연동
  biometricBinding,

  /// 하드웨어 키 증명 (Attestation)
  keyAttestation,
}

/// HSM 상태
enum HsmStatus {
  /// 사용 가능
  available,

  /// 사용 불가 (하드웨어 미지원)
  unavailable,

  /// 초기화되지 않음
  uninitialized,

  /// 잠김 (인증 필요)
  locked,

  /// 에러 상태
  error,
}

/// HSM 정보
///
/// 하드웨어 보안 모듈의 기본 정보와 지원 기능
class HsmInfo extends Equatable {
  /// HSM 이름 (예: "Secure Enclave", "StrongBox")
  final String name;

  /// HSM 버전
  final String version;

  /// 현재 상태
  final HsmStatus status;

  /// 지원하는 기능 목록
  final List<HsmCapability> supportedCapabilities;

  /// 하드웨어 기반 여부
  final bool isHardwareBacked;

  /// StrongBox 레벨 지원 (Android)
  final bool isStrongBox;

  /// Secure Enclave 지원 (iOS)
  final bool isSecureEnclave;

  const HsmInfo({
    required this.name,
    required this.version,
    required this.status,
    required this.supportedCapabilities,
    required this.isHardwareBacked,
    this.isStrongBox = false,
    this.isSecureEnclave = false,
  });

  /// 소프트웨어 폴백 HSM
  factory HsmInfo.softwareFallback() {
    return const HsmInfo(
      name: 'Software KeyStore',
      version: '1.0',
      status: HsmStatus.available,
      supportedCapabilities: [
        HsmCapability.keyGeneration,
        HsmCapability.signing,
        HsmCapability.verification,
        HsmCapability.encryption,
        HsmCapability.decryption,
      ],
      isHardwareBacked: false,
    );
  }

  /// Android StrongBox HSM
  factory HsmInfo.strongBox({
    required String version,
    required HsmStatus status,
  }) {
    return HsmInfo(
      name: 'Android StrongBox',
      version: version,
      status: status,
      supportedCapabilities: const [
        HsmCapability.keyGeneration,
        HsmCapability.signing,
        HsmCapability.verification,
        HsmCapability.keyAttestation,
        HsmCapability.biometricBinding,
      ],
      isHardwareBacked: true,
      isStrongBox: true,
    );
  }

  /// iOS Secure Enclave HSM
  factory HsmInfo.secureEnclave({
    required String version,
    required HsmStatus status,
  }) {
    return HsmInfo(
      name: 'Secure Enclave',
      version: version,
      status: status,
      supportedCapabilities: const [
        HsmCapability.keyGeneration,
        HsmCapability.signing,
        HsmCapability.verification,
        HsmCapability.biometricBinding,
        HsmCapability.keyAttestation,
      ],
      isHardwareBacked: true,
      isSecureEnclave: true,
    );
  }

  /// 특정 기능 지원 여부 확인
  bool supportsCapability(HsmCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  /// 사용 가능 여부
  bool get isAvailable => status == HsmStatus.available;

  @override
  List<Object?> get props => [
        name,
        version,
        status,
        supportedCapabilities,
        isHardwareBacked,
        isStrongBox,
        isSecureEnclave,
      ];

  @override
  String toString() {
    return 'HsmInfo(name: $name, version: $version, status: $status, '
        'hardwareBacked: $isHardwareBacked)';
  }
}
