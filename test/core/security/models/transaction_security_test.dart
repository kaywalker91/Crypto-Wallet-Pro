import 'package:crypto_wallet_pro/core/security/models/transaction_security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityCheckResult', () {
    test('should create passed result', () {
      const result = SecurityCheckResult.passed('Test Check');

      expect(result.passed, true);
      expect(result.checkName, 'Test Check');
      expect(result.failureReason, null);
      expect(result.severity, 0.0);
    });

    test('should create failed result', () {
      const result = SecurityCheckResult.failed(
        'Test Check',
        reason: 'Test failure',
        severity: 0.8,
      );

      expect(result.passed, false);
      expect(result.checkName, 'Test Check');
      expect(result.failureReason, 'Test failure');
      expect(result.severity, 0.8);
    });

    test('should support equality comparison', () {
      const result1 = SecurityCheckResult.passed('Check A');
      const result2 = SecurityCheckResult.passed('Check A');
      const result3 = SecurityCheckResult.failed('Check B', reason: 'Error');

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });

  group('TransactionSecurityContext', () {
    test('should create security context with all checks passed', () {
      final checks = [
        const SecurityCheckResult.passed('Check 1'),
        const SecurityCheckResult.passed('Check 2'),
      ];

      final context = TransactionSecurityContext(
        isSecure: true,
        checks: checks,
        riskScore: 0.0,
        timestamp: DateTime.now(),
      );

      expect(context.isSecure, true);
      expect(context.checks.length, 2);
      expect(context.riskScore, 0.0);
      expect(context.failedChecks, isEmpty);
      expect(context.hasCriticalFailures, false);
      expect(context.isSafeForSigning, true);
    });

    test('should identify failed checks', () {
      final checks = [
        const SecurityCheckResult.passed('Check 1'),
        const SecurityCheckResult.failed(
          'Check 2',
          reason: 'Failed',
          severity: 0.5,
        ),
      ];

      final context = TransactionSecurityContext(
        isSecure: false,
        checks: checks,
        riskScore: 0.5,
        timestamp: DateTime.now(),
      );

      expect(context.failedChecks.length, 1);
      expect(context.failedChecks.first.checkName, 'Check 2');
    });

    test('should detect critical failures', () {
      final checks = [
        const SecurityCheckResult.failed(
          'Critical Check',
          reason: 'Critical failure',
          severity: 0.9,
        ),
      ];

      final context = TransactionSecurityContext(
        isSecure: false,
        checks: checks,
        riskScore: 0.9,
        timestamp: DateTime.now(),
      );

      expect(context.hasCriticalFailures, true);
      expect(context.isSafeForSigning, false);
    });

    test('should not be safe for signing with critical failures', () {
      final context = TransactionSecurityContext(
        isSecure: true,
        checks: [
          const SecurityCheckResult.failed(
            'Check',
            reason: 'Critical',
            severity: 0.85,
          ),
        ],
        riskScore: 0.2,
        timestamp: DateTime.now(),
      );

      expect(context.isSafeForSigning, false);
    });
  });

  group('TransactionData', () {
    test('should create transaction data', () {
      final txData = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000000000000000000), // 1 ETH
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000), // 20 Gwei
        nonce: 5,
        chainId: 1,
      );

      expect(txData.to, '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3');
      expect(txData.value, BigInt.from(1000000000000000000));
      expect(txData.gasLimit, 21000);
      expect(txData.nonce, 5);
      expect(txData.chainId, 1);
      expect(txData.data, null);
    });

    test('should create transaction with data', () {
      final txData = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.zero,
        gasLimit: 100000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
        data: '0xa9059cbb',
        chainId: 1,
      );

      expect(txData.data, '0xa9059cbb');
    });

    test('should convert to map', () {
      final txData = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 5,
        chainId: 1,
      );

      final map = txData.toMap();

      expect(map['to'], '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3');
      expect(map['value'], '1000');
      expect(map['gasLimit'], 21000);
      expect(map['nonce'], 5);
      expect(map['chainId'], 1);
      expect(map['data'], '0x');
    });

    test('should support equality comparison', () {
      final txData1 = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 5,
      );

      final txData2 = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 5,
      );

      expect(txData1, equals(txData2));
    });
  });

  group('SignedTransaction', () {
    test('should create signed transaction', () {
      final txData = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 5,
      );

      final context = TransactionSecurityContext(
        isSecure: true,
        checks: [const SecurityCheckResult.passed('All checks')],
        riskScore: 0.0,
        timestamp: DateTime.now(),
      );

      final signed = SignedTransaction(
        transaction: txData,
        signature: '0xabcdef',
        txHash: '0x123456',
        signedAt: DateTime.now(),
        securityContext: context,
      );

      expect(signed.transaction, txData);
      expect(signed.signature, '0xabcdef');
      expect(signed.txHash, '0x123456');
      expect(signed.rawTransaction, '0xabcdef');
    });
  });

  group('TransactionSecurityConfig', () {
    test('should create default config', () {
      const config = TransactionSecurityConfig();

      expect(config.overlayProtectionEnabled, true);
      expect(config.recordingDetectionEnabled, true);
      expect(config.screenshotDetectionEnabled, true);
      expect(config.blockCompromisedDevices, true);
      expect(config.requireBiometrics, false);
      expect(config.maxAllowedRiskScore, 0.3);
    });

    test('should create strict config', () {
      const config = TransactionSecurityConfig.strict();

      expect(config.overlayProtectionEnabled, true);
      expect(config.recordingDetectionEnabled, true);
      expect(config.screenshotDetectionEnabled, true);
      expect(config.blockCompromisedDevices, true);
      expect(config.requireBiometrics, true);
      expect(config.maxAllowedRiskScore, 0.1);
    });

    test('should create relaxed config', () {
      const config = TransactionSecurityConfig.relaxed();

      expect(config.overlayProtectionEnabled, false);
      expect(config.recordingDetectionEnabled, false);
      expect(config.screenshotDetectionEnabled, false);
      expect(config.blockCompromisedDevices, false);
      expect(config.requireBiometrics, false);
      expect(config.maxAllowedRiskScore, 0.7);
    });

    test('should support copyWith', () {
      const config = TransactionSecurityConfig();
      final updated = config.copyWith(
        overlayProtectionEnabled: false,
        maxAllowedRiskScore: 0.5,
      );

      expect(updated.overlayProtectionEnabled, false);
      expect(updated.maxAllowedRiskScore, 0.5);
      expect(updated.recordingDetectionEnabled, true); // 변경되지 않음
    });

    test('should convert to and from JSON', () {
      const config = TransactionSecurityConfig(
        overlayProtectionEnabled: false,
        recordingDetectionEnabled: true,
        maxAllowedRiskScore: 0.6,
      );

      final json = config.toJson();
      final restored = TransactionSecurityConfig.fromJson(json);

      expect(restored, equals(config));
    });

    test('should support equality comparison', () {
      const config1 = TransactionSecurityConfig();
      const config2 = TransactionSecurityConfig();
      const config3 = TransactionSecurityConfig.strict();

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });
}
