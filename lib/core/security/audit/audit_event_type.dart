/// 보안 감사 이벤트 유형 및 심각도.
///
/// **이벤트 카테고리:**
/// - Authentication: 인증 관련 이벤트
/// - Encryption: 암호화/복호화 이벤트
/// - Wallet: 지갑 생성/삭제/접근 이벤트
/// - Transaction: 트랜잭션 서명/전송 이벤트
/// - Security: 보안 검사 및 위협 탐지 이벤트
/// - Settings: 보안 설정 변경 이벤트
enum AuditEventType {
  // Authentication Events (인증)
  authBiometricSuccess,
  authBiometricFailed,
  authPinSuccess,
  authPinFailed,
  authSessionExpired,

  // Encryption Events (암호화)
  encryptionSuccess,
  encryptionFailed,
  decryptionSuccess,
  decryptionFailed,
  keyDerivationSuccess,
  keyDerivationFailed,

  // Wallet Events (지갑 관리)
  walletCreated,
  walletImported,
  walletDeleted,
  walletExported,
  mnemonicAccessed,
  privateKeyAccessed,

  // Transaction Events (트랜잭션)
  transactionSigned,
  transactionSent,
  transactionFailed,

  // Security Events (보안)
  deviceIntegrityCheckPassed,
  deviceIntegrityCheckFailed,
  screenshotAttemptBlocked,
  suspiciousActivityDetected,

  // Settings Events (설정)
  biometricEnabled,
  biometricDisabled,
  pinChanged,
  securitySettingsChanged,
}

/// 감사 이벤트 심각도 수준.
enum AuditSeverity {
  /// 정보성 이벤트 (일반 작업).
  info,

  /// 경고 수준 (주의 필요).
  warning,

  /// 위험 수준 (즉시 조치 필요).
  critical,
}

/// [AuditEventType]의 확장 메서드.
extension AuditEventTypeExtension on AuditEventType {
  /// 이벤트의 심각도를 반환합니다.
  ///
  /// **심각도 분류:**
  /// - Critical: 실패 이벤트, 보안 위협, 민감 정보 접근
  /// - Warning: 디바이스 무결성 실패, 세션 만료
  /// - Info: 성공 이벤트, 일반 설정 변경
  AuditSeverity get severity {
    switch (this) {
      // Critical Events
      case AuditEventType.authBiometricFailed:
      case AuditEventType.authPinFailed:
      case AuditEventType.encryptionFailed:
      case AuditEventType.decryptionFailed:
      case AuditEventType.keyDerivationFailed:
      case AuditEventType.walletDeleted:
      case AuditEventType.mnemonicAccessed:
      case AuditEventType.privateKeyAccessed:
      case AuditEventType.transactionFailed:
      case AuditEventType.deviceIntegrityCheckFailed:
      case AuditEventType.suspiciousActivityDetected:
        return AuditSeverity.critical;

      // Warning Events
      case AuditEventType.authSessionExpired:
      case AuditEventType.screenshotAttemptBlocked:
        return AuditSeverity.warning;

      // Info Events
      case AuditEventType.authBiometricSuccess:
      case AuditEventType.authPinSuccess:
      case AuditEventType.encryptionSuccess:
      case AuditEventType.decryptionSuccess:
      case AuditEventType.keyDerivationSuccess:
      case AuditEventType.walletCreated:
      case AuditEventType.walletImported:
      case AuditEventType.walletExported:
      case AuditEventType.transactionSigned:
      case AuditEventType.transactionSent:
      case AuditEventType.deviceIntegrityCheckPassed:
      case AuditEventType.biometricEnabled:
      case AuditEventType.biometricDisabled:
      case AuditEventType.pinChanged:
      case AuditEventType.securitySettingsChanged:
        return AuditSeverity.info;
    }
  }

  /// 이벤트 카테고리를 반환합니다.
  String get category {
    switch (this) {
      case AuditEventType.authBiometricSuccess:
      case AuditEventType.authBiometricFailed:
      case AuditEventType.authPinSuccess:
      case AuditEventType.authPinFailed:
      case AuditEventType.authSessionExpired:
        return 'authentication';

      case AuditEventType.encryptionSuccess:
      case AuditEventType.encryptionFailed:
      case AuditEventType.decryptionSuccess:
      case AuditEventType.decryptionFailed:
      case AuditEventType.keyDerivationSuccess:
      case AuditEventType.keyDerivationFailed:
        return 'encryption';

      case AuditEventType.walletCreated:
      case AuditEventType.walletImported:
      case AuditEventType.walletDeleted:
      case AuditEventType.walletExported:
      case AuditEventType.mnemonicAccessed:
      case AuditEventType.privateKeyAccessed:
        return 'wallet';

      case AuditEventType.transactionSigned:
      case AuditEventType.transactionSent:
      case AuditEventType.transactionFailed:
        return 'transaction';

      case AuditEventType.deviceIntegrityCheckPassed:
      case AuditEventType.deviceIntegrityCheckFailed:
      case AuditEventType.screenshotAttemptBlocked:
      case AuditEventType.suspiciousActivityDetected:
        return 'security';

      case AuditEventType.biometricEnabled:
      case AuditEventType.biometricDisabled:
      case AuditEventType.pinChanged:
      case AuditEventType.securitySettingsChanged:
        return 'settings';
    }
  }

  /// 이벤트가 사용자 알림이 필요한지 여부를 반환합니다.
  ///
  /// Critical 심각도 이벤트는 알림이 필요합니다.
  bool get requiresAlert => severity == AuditSeverity.critical;

  /// 사람이 읽을 수 있는 이벤트 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case AuditEventType.authBiometricSuccess:
        return 'Biometric Authentication Success';
      case AuditEventType.authBiometricFailed:
        return 'Biometric Authentication Failed';
      case AuditEventType.authPinSuccess:
        return 'PIN Authentication Success';
      case AuditEventType.authPinFailed:
        return 'PIN Authentication Failed';
      case AuditEventType.authSessionExpired:
        return 'Authentication Session Expired';
      case AuditEventType.encryptionSuccess:
        return 'Encryption Success';
      case AuditEventType.encryptionFailed:
        return 'Encryption Failed';
      case AuditEventType.decryptionSuccess:
        return 'Decryption Success';
      case AuditEventType.decryptionFailed:
        return 'Decryption Failed';
      case AuditEventType.keyDerivationSuccess:
        return 'Key Derivation Success';
      case AuditEventType.keyDerivationFailed:
        return 'Key Derivation Failed';
      case AuditEventType.walletCreated:
        return 'Wallet Created';
      case AuditEventType.walletImported:
        return 'Wallet Imported';
      case AuditEventType.walletDeleted:
        return 'Wallet Deleted';
      case AuditEventType.walletExported:
        return 'Wallet Exported';
      case AuditEventType.mnemonicAccessed:
        return 'Mnemonic Accessed';
      case AuditEventType.privateKeyAccessed:
        return 'Private Key Accessed';
      case AuditEventType.transactionSigned:
        return 'Transaction Signed';
      case AuditEventType.transactionSent:
        return 'Transaction Sent';
      case AuditEventType.transactionFailed:
        return 'Transaction Failed';
      case AuditEventType.deviceIntegrityCheckPassed:
        return 'Device Integrity Check Passed';
      case AuditEventType.deviceIntegrityCheckFailed:
        return 'Device Integrity Check Failed';
      case AuditEventType.screenshotAttemptBlocked:
        return 'Screenshot Attempt Blocked';
      case AuditEventType.suspiciousActivityDetected:
        return 'Suspicious Activity Detected';
      case AuditEventType.biometricEnabled:
        return 'Biometric Enabled';
      case AuditEventType.biometricDisabled:
        return 'Biometric Disabled';
      case AuditEventType.pinChanged:
        return 'PIN Changed';
      case AuditEventType.securitySettingsChanged:
        return 'Security Settings Changed';
    }
  }
}

/// [AuditSeverity]의 확장 메서드.
extension AuditSeverityExtension on AuditSeverity {
  /// 심각도의 숫자 값을 반환합니다 (정렬용).
  int get numericValue {
    switch (this) {
      case AuditSeverity.info:
        return 0;
      case AuditSeverity.warning:
        return 1;
      case AuditSeverity.critical:
        return 2;
    }
  }

  /// 사람이 읽을 수 있는 심각도 이름을 반환합니다.
  String get displayName {
    switch (this) {
      case AuditSeverity.info:
        return 'Info';
      case AuditSeverity.warning:
        return 'Warning';
      case AuditSeverity.critical:
        return 'Critical';
    }
  }
}
