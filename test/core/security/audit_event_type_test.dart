import 'package:crypto_wallet_pro/core/security/audit/audit_event_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditEventType', () {
    group('severity', () {
      test('should return critical for failed authentication events', () {
        expect(
          AuditEventType.authBiometricFailed.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.authPinFailed.severity,
          AuditSeverity.critical,
        );
      });

      test('should return critical for failed encryption events', () {
        expect(
          AuditEventType.encryptionFailed.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.decryptionFailed.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.keyDerivationFailed.severity,
          AuditSeverity.critical,
        );
      });

      test('should return critical for sensitive wallet events', () {
        expect(
          AuditEventType.walletDeleted.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.mnemonicAccessed.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.privateKeyAccessed.severity,
          AuditSeverity.critical,
        );
      });

      test('should return critical for security threats', () {
        expect(
          AuditEventType.deviceIntegrityCheckFailed.severity,
          AuditSeverity.critical,
        );
        expect(
          AuditEventType.suspiciousActivityDetected.severity,
          AuditSeverity.critical,
        );
      });

      test('should return warning for session expiration', () {
        expect(
          AuditEventType.authSessionExpired.severity,
          AuditSeverity.warning,
        );
      });

      test('should return warning for screenshot attempt', () {
        expect(
          AuditEventType.screenshotAttemptBlocked.severity,
          AuditSeverity.warning,
        );
      });

      test('should return info for successful events', () {
        expect(
          AuditEventType.authBiometricSuccess.severity,
          AuditSeverity.info,
        );
        expect(
          AuditEventType.authPinSuccess.severity,
          AuditSeverity.info,
        );
        expect(
          AuditEventType.encryptionSuccess.severity,
          AuditSeverity.info,
        );
        expect(
          AuditEventType.walletCreated.severity,
          AuditSeverity.info,
        );
      });
    });

    group('category', () {
      test('should return authentication for auth events', () {
        expect(
          AuditEventType.authBiometricSuccess.category,
          'authentication',
        );
        expect(
          AuditEventType.authPinFailed.category,
          'authentication',
        );
        expect(
          AuditEventType.authSessionExpired.category,
          'authentication',
        );
      });

      test('should return encryption for crypto events', () {
        expect(
          AuditEventType.encryptionSuccess.category,
          'encryption',
        );
        expect(
          AuditEventType.decryptionFailed.category,
          'encryption',
        );
        expect(
          AuditEventType.keyDerivationSuccess.category,
          'encryption',
        );
      });

      test('should return wallet for wallet events', () {
        expect(
          AuditEventType.walletCreated.category,
          'wallet',
        );
        expect(
          AuditEventType.mnemonicAccessed.category,
          'wallet',
        );
      });

      test('should return transaction for tx events', () {
        expect(
          AuditEventType.transactionSigned.category,
          'transaction',
        );
        expect(
          AuditEventType.transactionSent.category,
          'transaction',
        );
      });

      test('should return security for security events', () {
        expect(
          AuditEventType.deviceIntegrityCheckPassed.category,
          'security',
        );
        expect(
          AuditEventType.suspiciousActivityDetected.category,
          'security',
        );
      });

      test('should return settings for settings events', () {
        expect(
          AuditEventType.biometricEnabled.category,
          'settings',
        );
        expect(
          AuditEventType.pinChanged.category,
          'settings',
        );
      });
    });

    group('requiresAlert', () {
      test('should return true for critical events', () {
        expect(AuditEventType.authPinFailed.requiresAlert, true);
        expect(AuditEventType.decryptionFailed.requiresAlert, true);
        expect(AuditEventType.mnemonicAccessed.requiresAlert, true);
      });

      test('should return false for warning events', () {
        expect(AuditEventType.authSessionExpired.requiresAlert, false);
        expect(AuditEventType.screenshotAttemptBlocked.requiresAlert, false);
      });

      test('should return false for info events', () {
        expect(AuditEventType.authBiometricSuccess.requiresAlert, false);
        expect(AuditEventType.walletCreated.requiresAlert, false);
      });
    });

    group('displayName', () {
      test('should return human-readable name', () {
        expect(
          AuditEventType.authBiometricSuccess.displayName,
          'Biometric Authentication Success',
        );
        expect(
          AuditEventType.walletCreated.displayName,
          'Wallet Created',
        );
        expect(
          AuditEventType.suspiciousActivityDetected.displayName,
          'Suspicious Activity Detected',
        );
      });
    });
  });

  group('AuditSeverity', () {
    group('numericValue', () {
      test('should return correct numeric values', () {
        expect(AuditSeverity.info.numericValue, 0);
        expect(AuditSeverity.warning.numericValue, 1);
        expect(AuditSeverity.critical.numericValue, 2);
      });

      test('should allow proper sorting', () {
        final severities = [
          AuditSeverity.critical,
          AuditSeverity.info,
          AuditSeverity.warning,
        ];
        severities.sort((a, b) => a.numericValue.compareTo(b.numericValue));

        expect(severities[0], AuditSeverity.info);
        expect(severities[1], AuditSeverity.warning);
        expect(severities[2], AuditSeverity.critical);
      });
    });

    group('displayName', () {
      test('should return human-readable name', () {
        expect(AuditSeverity.info.displayName, 'Info');
        expect(AuditSeverity.warning.displayName, 'Warning');
        expect(AuditSeverity.critical.displayName, 'Critical');
      });
    });
  });
}
