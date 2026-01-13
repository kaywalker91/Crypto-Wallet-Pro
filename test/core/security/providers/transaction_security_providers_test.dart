import 'package:crypto_wallet_pro/core/security/models/transaction_security.dart';
import 'package:crypto_wallet_pro/core/security/providers/transaction_security_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionSecurityConfigNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default config', () {
      final config =
          container.read(transactionSecurityConfigProvider);

      expect(config.overlayProtectionEnabled, true);
      expect(config.recordingDetectionEnabled, true);
      expect(config.screenshotDetectionEnabled, true);
      expect(config.blockCompromisedDevices, true);
      expect(config.requireBiometrics, false);
      expect(config.maxAllowedRiskScore, 0.3);
    });

    test('should update config', () {
      const newConfig = TransactionSecurityConfig(
        overlayProtectionEnabled: false,
        maxAllowedRiskScore: 0.5,
      );

      container
          .read(transactionSecurityConfigProvider.notifier)
          .updateConfig(newConfig);

      final config =
          container.read(transactionSecurityConfigProvider);

      expect(config.overlayProtectionEnabled, false);
      expect(config.maxAllowedRiskScore, 0.5);
    });

    test('should enable strict mode', () {
      container
          .read(transactionSecurityConfigProvider.notifier)
          .enableStrictMode();

      final config =
          container.read(transactionSecurityConfigProvider);

      expect(config.overlayProtectionEnabled, true);
      expect(config.recordingDetectionEnabled, true);
      expect(config.screenshotDetectionEnabled, true);
      expect(config.blockCompromisedDevices, true);
      expect(config.requireBiometrics, true);
      expect(config.maxAllowedRiskScore, 0.1);
    });

    test('should enable relaxed mode', () {
      container
          .read(transactionSecurityConfigProvider.notifier)
          .enableRelaxedMode();

      final config =
          container.read(transactionSecurityConfigProvider);

      expect(config.overlayProtectionEnabled, false);
      expect(config.recordingDetectionEnabled, false);
      expect(config.screenshotDetectionEnabled, false);
      expect(config.blockCompromisedDevices, false);
      expect(config.requireBiometrics, false);
      expect(config.maxAllowedRiskScore, 0.7);
    });

    test('should toggle overlay protection', () {
      final initialValue =
          container.read(transactionSecurityConfigProvider)
              .overlayProtectionEnabled;

      container
          .read(transactionSecurityConfigProvider.notifier)
          .toggleOverlayProtection();

      final newValue = container.read(transactionSecurityConfigProvider)
          .overlayProtectionEnabled;

      expect(newValue, !initialValue);
    });

    test('should toggle recording detection', () {
      final initialValue =
          container.read(transactionSecurityConfigProvider)
              .recordingDetectionEnabled;

      container
          .read(transactionSecurityConfigProvider.notifier)
          .toggleRecordingDetection();

      final newValue = container.read(transactionSecurityConfigProvider)
          .recordingDetectionEnabled;

      expect(newValue, !initialValue);
    });

    test('should toggle screenshot detection', () {
      final initialValue =
          container.read(transactionSecurityConfigProvider)
              .screenshotDetectionEnabled;

      container
          .read(transactionSecurityConfigProvider.notifier)
          .toggleScreenshotDetection();

      final newValue = container.read(transactionSecurityConfigProvider)
          .screenshotDetectionEnabled;

      expect(newValue, !initialValue);
    });

    test('should toggle block compromised devices', () {
      final initialValue =
          container.read(transactionSecurityConfigProvider)
              .blockCompromisedDevices;

      container
          .read(transactionSecurityConfigProvider.notifier)
          .toggleBlockCompromisedDevices();

      final newValue = container.read(transactionSecurityConfigProvider)
          .blockCompromisedDevices;

      expect(newValue, !initialValue);
    });

    test('should toggle require biometrics', () {
      final initialValue =
          container.read(transactionSecurityConfigProvider)
              .requireBiometrics;

      container
          .read(transactionSecurityConfigProvider.notifier)
          .toggleRequireBiometrics();

      final newValue =
          container.read(transactionSecurityConfigProvider)
              .requireBiometrics;

      expect(newValue, !initialValue);
    });

    test('should set max risk score', () {
      container
          .read(transactionSecurityConfigProvider.notifier)
          .setMaxRiskScore(0.8);

      final config =
          container.read(transactionSecurityConfigProvider);

      expect(config.maxAllowedRiskScore, 0.8);
    });
  });

  group('TransactionSecurityState', () {
    test('should create initial state', () {
      const state = TransactionSecurityState();

      expect(state.currentContext, null);
      expect(state.isPreparingContext, false);
      expect(state.error, null);
      expect(state.isSafeForSigning, false);
      expect(state.riskScore, 1.0);
      expect(state.failedChecks, isEmpty);
    });

    test('should copy state with new values', () {
      const initialState = TransactionSecurityState();
      final context = TransactionSecurityContext(
        isSecure: true,
        checks: [const SecurityCheckResult.passed('Test')],
        riskScore: 0.0,
        timestamp: DateTime.now(),
      );

      final newState = initialState.copyWith(
        currentContext: context,
        isPreparingContext: true,
      );

      expect(newState.currentContext, context);
      expect(newState.isPreparingContext, true);
      expect(newState.error, null);
    });

    test('should report safe for signing when context is secure', () {
      final context = TransactionSecurityContext(
        isSecure: true,
        checks: [const SecurityCheckResult.passed('Test')],
        riskScore: 0.0,
        timestamp: DateTime.now(),
      );

      final state = TransactionSecurityState(currentContext: context);

      expect(state.isSafeForSigning, true);
      expect(state.riskScore, 0.0);
    });

    test('should report failed checks from context', () {
      final context = TransactionSecurityContext(
        isSecure: false,
        checks: [
          const SecurityCheckResult.passed('Check 1'),
          const SecurityCheckResult.failed(
            'Check 2',
            reason: 'Failed',
            severity: 0.7,
          ),
        ],
        riskScore: 0.7,
        timestamp: DateTime.now(),
      );

      final state = TransactionSecurityState(currentContext: context);

      expect(state.failedChecks.length, 1);
      expect(state.failedChecks.first.checkName, 'Check 2');
    });
  });

  group('Service Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('overlayProtectionServiceProvider should be accessible', () {
      final service = container.read(overlayProtectionServiceProvider);
      expect(service, isNotNull);
    });

    test('tamperDetectionServiceProvider should be accessible', () {
      final service = container.read(tamperDetectionServiceProvider);
      expect(service, isNotNull);
    });

    test('screenshotDetectionServiceProvider should be accessible', () {
      final service = container.read(screenshotDetectionServiceProvider);
      expect(service, isNotNull);
    });

    test('screenRecordingDetectionServiceProvider should be accessible', () {
      final service = container.read(screenRecordingDetectionServiceProvider);
      expect(service, isNotNull);
    });

    test('deviceIntegrityServiceProvider should be accessible', () {
      final service = container.read(deviceIntegrityServiceProvider);
      expect(service, isNotNull);
    });

    test('secureTransactionSignerProvider should be accessible', () {
      final service = container.read(secureTransactionSignerProvider);
      expect(service, isNotNull);
    });

    test('secureTransactionSignerProvider should use current config', () {
      // Config 변경
      container
          .read(transactionSecurityConfigProvider.notifier)
          .enableStrictMode();

      // Signer가 새 config를 사용하는지 확인
      final signer = container.read(secureTransactionSignerProvider);
      expect(signer.config.maxAllowedRiskScore, 0.1);
    });
  });
}
