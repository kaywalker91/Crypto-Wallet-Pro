import 'package:equatable/equatable.dart';

/// 보안 검사 결과
class SecurityCheckResult extends Equatable {
  final bool passed;
  final String checkName;
  final String? failureReason;
  final double severity; // 0.0 = info, 1.0 = critical

  const SecurityCheckResult({
    required this.passed,
    required this.checkName,
    this.failureReason,
    this.severity = 0.5,
  });

  const SecurityCheckResult.passed(String checkName)
      : this(passed: true, checkName: checkName, severity: 0.0);

  const SecurityCheckResult.failed(
    String checkName, {
    required String reason,
    double severity = 0.5,
  }) : this(
          passed: false,
          checkName: checkName,
          failureReason: reason,
          severity: severity,
        );

  @override
  List<Object?> get props => [passed, checkName, failureReason, severity];
}

/// 트랜잭션 보안 컨텍스트
///
/// 트랜잭션 서명 전 보안 환경을 검증한 결과를 담습니다.
class TransactionSecurityContext extends Equatable {
  /// 전체 보안 검사 통과 여부
  final bool isSecure;

  /// 개별 보안 검사 결과 목록
  final List<SecurityCheckResult> checks;

  /// 전체 위험도 (0.0 = 안전, 1.0 = 매우 위험)
  final double riskScore;

  /// 검사 수행 시간
  final DateTime timestamp;

  const TransactionSecurityContext({
    required this.isSecure,
    required this.checks,
    required this.riskScore,
    required this.timestamp,
  });

  /// 실패한 검사 목록
  List<SecurityCheckResult> get failedChecks =>
      checks.where((c) => !c.passed).toList();

  /// 치명적인 실패 (severity >= 0.8)가 있는지
  bool get hasCriticalFailures =>
      failedChecks.any((c) => c.severity >= 0.8);

  /// 보안 컨텍스트가 트랜잭션 서명에 적합한지
  bool get isSafeForSigning => isSecure && !hasCriticalFailures;

  @override
  List<Object?> get props => [isSecure, checks, riskScore, timestamp];

  @override
  String toString() {
    return 'TransactionSecurityContext(isSecure: $isSecure, '
        'riskScore: $riskScore, failedChecks: ${failedChecks.length})';
  }
}

/// 트랜잭션 데이터 모델
///
/// 서명할 트랜잭션의 정보를 담습니다.
class TransactionData extends Equatable {
  /// 수신자 주소
  final String to;

  /// 전송 금액 (Wei)
  final BigInt value;

  /// 가스 한도
  final int gasLimit;

  /// 가스 가격 (Wei)
  final BigInt gasPrice;

  /// 논스
  final int nonce;

  /// 추가 데이터 (스마트 컨트랙트 호출 시)
  final String? data;

  /// 체인 ID
  final int chainId;

  const TransactionData({
    required this.to,
    required this.value,
    required this.gasLimit,
    required this.gasPrice,
    required this.nonce,
    this.data,
    this.chainId = 1, // Ethereum Mainnet
  });

  /// 트랜잭션 해시 계산용 데이터
  Map<String, dynamic> toMap() {
    return {
      'to': to,
      'value': value.toString(),
      'gasLimit': gasLimit,
      'gasPrice': gasPrice.toString(),
      'nonce': nonce,
      'data': data ?? '0x',
      'chainId': chainId,
    };
  }

  @override
  List<Object?> get props =>
      [to, value, gasLimit, gasPrice, nonce, data, chainId];

  @override
  String toString() {
    return 'TransactionData(to: $to, value: $value, nonce: $nonce, '
        'chainId: $chainId)';
  }
}

/// 서명된 트랜잭션 결과
class SignedTransaction extends Equatable {
  /// 원본 트랜잭션 데이터
  final TransactionData transaction;

  /// 서명 (r, s, v)
  final String signature;

  /// 서명된 트랜잭션 해시
  final String txHash;

  /// 서명 시간
  final DateTime signedAt;

  /// 보안 컨텍스트 (서명 당시의 보안 상태)
  final TransactionSecurityContext securityContext;

  const SignedTransaction({
    required this.transaction,
    required this.signature,
    required this.txHash,
    required this.signedAt,
    required this.securityContext,
  });

  /// RLP 인코딩된 서명 트랜잭션 (브로드캐스트용)
  String get rawTransaction => signature;

  @override
  List<Object?> get props =>
      [transaction, signature, txHash, signedAt, securityContext];

  @override
  String toString() {
    return 'SignedTransaction(txHash: $txHash, signedAt: $signedAt)';
  }
}

/// 트랜잭션 보안 설정
class TransactionSecurityConfig extends Equatable {
  /// 오버레이 공격 방지 활성화
  final bool overlayProtectionEnabled;

  /// 화면 녹화 감지 활성화
  final bool recordingDetectionEnabled;

  /// 스크린샷 감지 활성화
  final bool screenshotDetectionEnabled;

  /// 루팅/탈옥 기기 차단
  final bool blockCompromisedDevices;

  /// 생체 인증 필수 여부
  final bool requireBiometrics;

  /// 최대 허용 위험도 (0.0 ~ 1.0)
  final double maxAllowedRiskScore;

  const TransactionSecurityConfig({
    this.overlayProtectionEnabled = true,
    this.recordingDetectionEnabled = true,
    this.screenshotDetectionEnabled = true,
    this.blockCompromisedDevices = true,
    this.requireBiometrics = false,
    this.maxAllowedRiskScore = 0.3,
  });

  /// 기본 설정 (보안 강화)
  const TransactionSecurityConfig.strict()
      : this(
          overlayProtectionEnabled: true,
          recordingDetectionEnabled: true,
          screenshotDetectionEnabled: true,
          blockCompromisedDevices: true,
          requireBiometrics: true,
          maxAllowedRiskScore: 0.1,
        );

  /// 느슨한 설정 (편의성 우선)
  const TransactionSecurityConfig.relaxed()
      : this(
          overlayProtectionEnabled: false,
          recordingDetectionEnabled: false,
          screenshotDetectionEnabled: false,
          blockCompromisedDevices: false,
          requireBiometrics: false,
          maxAllowedRiskScore: 0.7,
        );

  TransactionSecurityConfig copyWith({
    bool? overlayProtectionEnabled,
    bool? recordingDetectionEnabled,
    bool? screenshotDetectionEnabled,
    bool? blockCompromisedDevices,
    bool? requireBiometrics,
    double? maxAllowedRiskScore,
  }) {
    return TransactionSecurityConfig(
      overlayProtectionEnabled:
          overlayProtectionEnabled ?? this.overlayProtectionEnabled,
      recordingDetectionEnabled:
          recordingDetectionEnabled ?? this.recordingDetectionEnabled,
      screenshotDetectionEnabled:
          screenshotDetectionEnabled ?? this.screenshotDetectionEnabled,
      blockCompromisedDevices:
          blockCompromisedDevices ?? this.blockCompromisedDevices,
      requireBiometrics: requireBiometrics ?? this.requireBiometrics,
      maxAllowedRiskScore: maxAllowedRiskScore ?? this.maxAllowedRiskScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overlayProtectionEnabled': overlayProtectionEnabled,
      'recordingDetectionEnabled': recordingDetectionEnabled,
      'screenshotDetectionEnabled': screenshotDetectionEnabled,
      'blockCompromisedDevices': blockCompromisedDevices,
      'requireBiometrics': requireBiometrics,
      'maxAllowedRiskScore': maxAllowedRiskScore,
    };
  }

  factory TransactionSecurityConfig.fromJson(Map<String, dynamic> json) {
    return TransactionSecurityConfig(
      overlayProtectionEnabled:
          json['overlayProtectionEnabled'] as bool? ?? true,
      recordingDetectionEnabled:
          json['recordingDetectionEnabled'] as bool? ?? true,
      screenshotDetectionEnabled:
          json['screenshotDetectionEnabled'] as bool? ?? true,
      blockCompromisedDevices:
          json['blockCompromisedDevices'] as bool? ?? true,
      requireBiometrics: json['requireBiometrics'] as bool? ?? false,
      maxAllowedRiskScore: json['maxAllowedRiskScore'] as double? ?? 0.3,
    );
  }

  @override
  List<Object?> get props => [
        overlayProtectionEnabled,
        recordingDetectionEnabled,
        screenshotDetectionEnabled,
        blockCompromisedDevices,
        requireBiometrics,
        maxAllowedRiskScore,
      ];
}
