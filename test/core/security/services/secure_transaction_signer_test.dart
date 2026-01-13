import 'package:crypto_wallet_pro/core/security/models/transaction_security.dart';
import 'package:crypto_wallet_pro/core/security/services/device_integrity_service.dart';
import 'package:crypto_wallet_pro/core/security/services/overlay_protection_service.dart';
import 'package:crypto_wallet_pro/core/security/services/screen_recording_detection_service.dart';
import 'package:crypto_wallet_pro/core/security/services/screenshot_detection_service.dart';
import 'package:crypto_wallet_pro/core/security/services/secure_transaction_signer.dart';
import 'package:crypto_wallet_pro/core/security/services/tamper_detection_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  DeviceIntegrityService,
  OverlayProtectionService,
  TamperDetectionService,
  ScreenRecordingDetectionService,
  ScreenshotDetectionService,
])
import 'secure_transaction_signer_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureTransactionSigner signer;
  late MockDeviceIntegrityService mockDeviceIntegrity;
  late MockOverlayProtectionService mockOverlay;
  late MockTamperDetectionService mockTamper;
  late MockScreenRecordingDetectionService mockRecording;
  late MockScreenshotDetectionService mockScreenshot;

  setUp(() {
    mockDeviceIntegrity = MockDeviceIntegrityService();
    mockOverlay = MockOverlayProtectionService();
    mockTamper = MockTamperDetectionService();
    mockRecording = MockScreenRecordingDetectionService();
    mockScreenshot = MockScreenshotDetectionService();

    // Default mock behaviors
    when(mockDeviceIntegrity.checkDeviceIntegrity()).thenAnswer(
      (_) async => const DeviceIntegrityResult(
        status: DeviceIntegrityStatus.secure,
        details: [],
        riskLevel: 0.0,
      ),
    );

    when(mockTamper.verifyAppIntegrity()).thenAnswer(
      (_) async => TamperDetectionResult(
        isIntact: true,
        violations: [],
        riskLevel: 0.0,
        timestamp: DateTime.now(),
      ),
    );

    when(mockOverlay.checkOverlayStatus()).thenAnswer(
      (_) async => const OverlayStatus(
        hasOverlay: false,
        suspiciousApps: [],
        threatLevel: 0.0,
      ),
    );

    when(mockOverlay.enableStrictMode()).thenAnswer((_) async => true);
    when(mockOverlay.disableStrictMode()).thenAnswer((_) async => true);

    when(mockRecording.isRecordingActive())
        .thenAnswer((_) async => ScreenRecordingStatus.notRecording);

    when(mockScreenshot.isSupported()).thenAnswer((_) async => true);

    signer = SecureTransactionSigner(
      config: const TransactionSecurityConfig(),
      deviceIntegrityService: mockDeviceIntegrity,
      overlayProtectionService: mockOverlay,
      tamperDetectionService: mockTamper,
      recordingDetectionService: mockRecording,
      screenshotDetectionService: mockScreenshot,
    );
  });

  group('SecureTransactionSigner - prepareSecureContext', () {
    test('should pass all security checks', () async {
      final context = await signer.prepareSecureContext();

      expect(context.isSecure, true);
      expect(context.checks.length, greaterThan(0));
      expect(context.failedChecks, isEmpty);
      expect(context.riskScore, lessThanOrEqualTo(0.3));
      expect(context.isSafeForSigning, true);

      verify(mockDeviceIntegrity.checkDeviceIntegrity()).called(1);
      verify(mockTamper.verifyAppIntegrity()).called(1);
      verify(mockOverlay.checkOverlayStatus()).called(1);
      verify(mockRecording.isRecordingActive()).called(1);
    });

    test('should fail when device is compromised', () async {
      when(mockDeviceIntegrity.checkDeviceIntegrity()).thenAnswer(
        (_) async => const DeviceIntegrityResult(
          status: DeviceIntegrityStatus.rooted,
          details: ['su binary found'],
          riskLevel: 0.9,
        ),
      );

      final context = await signer.prepareSecureContext();

      expect(context.isSecure, false);
      expect(context.failedChecks.isNotEmpty, true);
      expect(context.isSafeForSigning, false);
    });

    test('should fail when app is tampered', () async {
      when(mockTamper.verifyAppIntegrity()).thenAnswer(
        (_) async => TamperDetectionResult(
          isIntact: false,
          violations: [
            const TamperViolation(
              type: TamperViolationType.invalidSignature,
              description: 'Invalid signature',
              severity: 1.0,
            ),
          ],
          riskLevel: 1.0,
          timestamp: DateTime.now(),
        ),
      );

      final context = await signer.prepareSecureContext();

      expect(context.isSecure, false);
      expect(context.hasCriticalFailures, true);
    });

    test('should fail when overlay is detected', () async {
      when(mockOverlay.checkOverlayStatus()).thenAnswer(
        (_) async => const OverlayStatus(
          hasOverlay: true,
          suspiciousApps: ['com.malware.overlay'],
          threatLevel: 0.8,
        ),
      );

      final context = await signer.prepareSecureContext();

      expect(context.isSecure, false);
      expect(
          context.failedChecks
              .any((c) => c.checkName == 'Overlay Protection'),
          true);
    });

    test('should fail when screen recording is active', () async {
      when(mockRecording.isRecordingActive())
          .thenAnswer((_) async => ScreenRecordingStatus.recording);

      final context = await signer.prepareSecureContext();

      expect(context.isSecure, false);
      expect(
          context.failedChecks.any((c) => c.checkName == 'Screen Recording'),
          true);
    });

    test('should enable overlay strict mode', () async {
      await signer.prepareSecureContext();

      verify(mockOverlay.enableStrictMode()).called(1);
    });

    test('should handle errors gracefully', () async {
      when(mockDeviceIntegrity.checkDeviceIntegrity())
          .thenThrow(Exception('Test error'));

      final context = await signer.prepareSecureContext();

      expect(context.isSecure, false);
      expect(context.riskScore, 1.0);
    });
  });

  group('SecureTransactionSigner - signTransaction', () {
    // 올바른 42자 이더리움 주소 (0x + 40 hex chars)
    final validTransaction = TransactionData(
      to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
      value: BigInt.from(1000000000000000000),
      gasLimit: 21000,
      gasPrice: BigInt.from(20000000000),
      nonce: 0,
      chainId: 1,
    );

    test('should sign transaction successfully', () async {
      final signed = await signer.signTransaction(validTransaction, '123456');

      expect(signed.transaction, validTransaction);
      expect(signed.signature, isNotEmpty);
      expect(signed.txHash, isNotEmpty);
      expect(signed.txHash.startsWith('0x'), true);

      verify(mockOverlay.disableStrictMode()).called(1);
    });

    test('should throw SecurityException when context is unsafe', () async {
      when(mockDeviceIntegrity.checkDeviceIntegrity()).thenAnswer(
        (_) async => const DeviceIntegrityResult(
          status: DeviceIntegrityStatus.rooted,
          details: ['rooted'],
          riskLevel: 1.0,
        ),
      );

      expect(
        () => signer.signTransaction(validTransaction, '123456'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should throw ValidationException for invalid address', () async {
      final invalidTransaction = TransactionData(
        to: 'invalid_address',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      expect(
        () => signer.signTransaction(invalidTransaction, '123456'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw ValidationException for excessive gas price', () async {
      final highGasTransaction = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(2000) * BigInt.from(1e9), // 2000 Gwei
        nonce: 0,
      );

      expect(
        () => signer.signTransaction(highGasTransaction, '123456'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw ValidationException for negative value', () async {
      final negativeValueTransaction = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(-1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      expect(
        () => signer.signTransaction(negativeValueTransaction, '123456'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should include security context in signed transaction', () async {
      final signed = await signer.signTransaction(validTransaction, '123456');

      expect(signed.securityContext, isNotNull);
      expect(signed.securityContext.isSecure, true);
    });
  });

  group('SecureTransactionSigner - validateTransactionSecurity', () {
    test('should accept valid ethereum address', () async {
      final validTx = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc454795f0bEb3',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      await expectLater(
        signer.validateTransactionSecurity(validTx),
        completes,
      );
    });

    test('should reject address without 0x prefix', () async {
      final invalidTx = TransactionData(
        to: '742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      expect(
        () => signer.validateTransactionSecurity(invalidTx),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should reject address with wrong length', () async {
      final invalidTx = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0b',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      expect(
        () => signer.validateTransactionSecurity(invalidTx),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should reject non-hex characters in address', () async {
      final invalidTx = TransactionData(
        to: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEZ',
        value: BigInt.from(1000),
        gasLimit: 21000,
        gasPrice: BigInt.from(20000000000),
        nonce: 0,
      );

      expect(
        () => signer.validateTransactionSecurity(invalidTx),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('SecureTransactionSigner - with different configs', () {
    test('should work with strict config', () async {
      final strictSigner = SecureTransactionSigner(
        config: const TransactionSecurityConfig.strict(),
        deviceIntegrityService: mockDeviceIntegrity,
        overlayProtectionService: mockOverlay,
        tamperDetectionService: mockTamper,
        recordingDetectionService: mockRecording,
        screenshotDetectionService: mockScreenshot,
      );

      final context = await strictSigner.prepareSecureContext();
      expect(context.riskScore, lessThanOrEqualTo(0.1));
    });

    test('should work with relaxed config', () async {
      final relaxedSigner = SecureTransactionSigner(
        config: const TransactionSecurityConfig.relaxed(),
        deviceIntegrityService: mockDeviceIntegrity,
        overlayProtectionService: mockOverlay,
        tamperDetectionService: mockTamper,
        recordingDetectionService: mockRecording,
        screenshotDetectionService: mockScreenshot,
      );

      final context = await relaxedSigner.prepareSecureContext();

      // Relaxed config는 일부 검사를 건너뜀
      verifyNever(mockOverlay.enableStrictMode());
    });
  });
}
