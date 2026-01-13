/// Keys used for secure storage and local persistence.
class StorageKeys {
  StorageKeys._();

  static const String mnemonic = 'wallet_mnemonic';
  static const String walletAddress = 'wallet_address';
  static const String pin = 'wallet_pin';
  static const String pinSalt = 'wallet_pin_salt';
  static const String wallet = 'wallet_metadata';
  static const String authSessionValidUntil = 'auth_session_valid_until';
  static const String appSettings = 'app_settings';

  // Phase 6: Biometric-Protected Keys
  static const String biometricKey = 'wallet_biometric_key';
  static const String encryptedBiometricKey = 'wallet_encrypted_biometric_key';
  static const String biometricKeySalt = 'wallet_biometric_key_salt';

  // Phase 7: Security Audit Logging
  static const String auditLogs = 'wallet_audit_logs';
  static const String auditLogIndex = 'wallet_audit_log_index';
  static const String auditLogSalt = 'wallet_audit_log_salt';

  // Phase 8: Remote Security Sync
  static const String syncKey = 'wallet_sync_key';
  static const String syncSalt = 'wallet_sync_salt';
  static const String syncConfig = 'wallet_sync_config';
  static const String syncLastTime = 'wallet_sync_last_time';
  static const String syncOfflineQueue = 'wallet_sync_offline_queue';
  static const String syncDeviceId = 'wallet_sync_device_id';
  static const String syncDeviceRegistry = 'wallet_sync_device_registry';

  // Phase 9: Hardware Security
  static const String hsmKeyPrefix = 'wallet_hsm_key_';
  static const String attestationToken = 'wallet_attestation_token';
  static const String lastAttestationTime = 'wallet_last_attestation';
  static const String rootDetectionCache = 'wallet_root_detection_cache';
  static const String enclaveKeyId = 'wallet_enclave_key_id';

  // Phase 10: Transaction Security
  static const String transactionSecurityConfig = 'wallet_tx_security_config';
  static const String screenshotDetectionEnabled = 'wallet_screenshot_detection';
  static const String recordingDetectionEnabled = 'wallet_recording_detection';
  static const String overlayProtectionEnabled = 'wallet_overlay_protection';
  static const String lastIntegrityCheck = 'wallet_last_integrity_check';
}
