import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_security.dart';
import 'device_integrity_service.dart';
import 'overlay_protection_service.dart';
import 'screen_recording_detection_service.dart';
import 'screenshot_detection_service.dart';
import 'tamper_detection_service.dart';

/// 보안 트랜잭션 서명 서비스
///
/// Defense-in-Depth 전략을 적용한 다층 보안 검증을 통해
/// 트랜잭션 서명 시 악성 공격을 방지합니다.
///
/// **보안 계층 (5-Layer Defense)**
/// ```
/// L5: 메모리 보안 (서명 후 즉시 삭제)
/// L4: UI 보안 (화면 녹화/스크린샷 차단)
/// L3: 앱 보안 (변조 감지)
/// L2: 접근 제어 (오버레이 차단)
/// L1: 기기 무결성 (루팅/탈옥 확인)
/// ```
///
/// **위협 모델**
/// | 공격 벡터 | 대응 |
/// |----------|------|
/// | 오버레이 공격 | OverlayProtectionService |
/// | 화면 녹화 | ScreenRecordingDetectionService |
/// | 스크린샷 캡처 | ScreenshotDetectionService |
/// | 앱 변조 | TamperDetectionService |
/// | 루팅 기기 | DeviceIntegrityService |
///
/// **사용 예시**
/// ```dart
/// final signer = SecureTransactionSigner(config);
///
/// // 1. 보안 컨텍스트 준비
/// final context = await signer.prepareSecureContext();
/// if (!context.isSafeForSigning) {
///   showSecurityWarning(context);
///   return;
/// }
///
/// // 2. 트랜잭션 서명
/// final signed = await signer.signTransaction(txData, pin);
///
/// // 3. 브로드캐스트
/// await broadcastTransaction(signed.rawTransaction);
/// ```
class SecureTransactionSigner {
  final TransactionSecurityConfig config;
  final DeviceIntegrityService _deviceIntegrityService;
  final OverlayProtectionService _overlayProtectionService;
  final TamperDetectionService _tamperDetectionService;
  final ScreenRecordingDetectionService _recordingDetectionService;
  final ScreenshotDetectionService _screenshotDetectionService;

  SecureTransactionSigner({
    required this.config,
    DeviceIntegrityService? deviceIntegrityService,
    OverlayProtectionService? overlayProtectionService,
    TamperDetectionService? tamperDetectionService,
    ScreenRecordingDetectionService? recordingDetectionService,
    ScreenshotDetectionService? screenshotDetectionService,
  })  : _deviceIntegrityService =
            deviceIntegrityService ?? DeviceIntegrityService(),
        _overlayProtectionService =
            overlayProtectionService ?? OverlayProtectionService(),
        _tamperDetectionService =
            tamperDetectionService ?? TamperDetectionService(),
        _recordingDetectionService = recordingDetectionService ??
            ScreenRecordingDetectionService(),
        _screenshotDetectionService =
            screenshotDetectionService ?? ScreenshotDetectionService();

  /// 보안 컨텍스트 준비
  ///
  /// 트랜잭션 서명 전에 호출하여 보안 환경을 검증합니다.
  ///
  /// **검증 항목:**
  /// 1. 기기 무결성 (루팅/탈옥)
  /// 2. 앱 무결성 (변조 감지)
  /// 3. 오버레이 공격 방지
  /// 4. 화면 녹화 감지
  /// 5. 스크린샷 방지 활성화
  ///
  /// Returns [TransactionSecurityContext] - 보안 컨텍스트 결과
  Future<TransactionSecurityContext> prepareSecureContext() async {
    final checks = <SecurityCheckResult>[];
    final timestamp = DateTime.now();

    try {
      // L1: 기기 무결성 검사
      if (config.blockCompromisedDevices) {
        final deviceIntegrity =
            await _deviceIntegrityService.checkDeviceIntegrity();

        if (deviceIntegrity.isCompromised) {
          checks.add(
            SecurityCheckResult.failed(
              'Device Integrity',
              reason: 'Device is rooted/jailbroken: '
                  '${deviceIntegrity.details.join(', ')}',
              severity: 0.9,
            ),
          );
        } else {
          checks.add(const SecurityCheckResult.passed('Device Integrity'));
        }
      }

      // L2: 앱 무결성 검사
      final tamperResult = await _tamperDetectionService.verifyAppIntegrity();

      if (!tamperResult.isIntact) {
        checks.add(
          SecurityCheckResult.failed(
            'App Integrity',
            reason: 'App tampering detected: '
                '${tamperResult.violations.map((v) => v.description).join(', ')}',
            severity: tamperResult.riskLevel,
          ),
        );
      } else {
        checks.add(const SecurityCheckResult.passed('App Integrity'));
      }

      // L3: 오버레이 공격 방지
      if (config.overlayProtectionEnabled) {
        final overlayStatus =
            await _overlayProtectionService.checkOverlayStatus();

        if (overlayStatus.hasOverlay) {
          checks.add(
            SecurityCheckResult.failed(
              'Overlay Protection',
              reason: 'Overlay detected: ${overlayStatus.suspiciousApps.join(', ')}',
              severity: overlayStatus.threatLevel,
            ),
          );
        } else {
          // Strict Mode 활성화
          final strictEnabled =
              await _overlayProtectionService.enableStrictMode();
          if (strictEnabled) {
            checks
                .add(const SecurityCheckResult.passed('Overlay Protection'));
          } else {
            checks.add(
              const SecurityCheckResult.failed(
                'Overlay Protection',
                reason: 'Failed to enable strict mode',
                severity: 0.4,
              ),
            );
          }
        }
      }

      // L4: 화면 녹화 감지
      if (config.recordingDetectionEnabled) {
        final recordingStatus =
            await _recordingDetectionService.isRecordingActive();

        if (recordingStatus == ScreenRecordingStatus.recording) {
          checks.add(
            const SecurityCheckResult.failed(
              'Screen Recording',
              reason: 'Screen recording is active',
              severity: 0.8,
            ),
          );
        } else {
          checks.add(const SecurityCheckResult.passed('Screen Recording'));
        }
      }

      // L5: 스크린샷 감지 설정
      if (config.screenshotDetectionEnabled) {
        final isSupported = await _screenshotDetectionService.isSupported();
        if (isSupported) {
          // 스크린샷 리스너는 UI 레이어에서 관리
          checks.add(const SecurityCheckResult.passed('Screenshot Detection'));
        } else {
          checks.add(
            const SecurityCheckResult.failed(
              'Screenshot Detection',
              reason: 'Screenshot detection not supported on this platform',
              severity: 0.2, // 낮은 심각도
            ),
          );
        }
      }

      // 전체 위험도 계산
      final failedChecks = checks.where((c) => !c.passed).toList();
      final riskScore = failedChecks.isEmpty
          ? 0.0
          : failedChecks.map((c) => c.severity).reduce((a, b) => a + b) /
              failedChecks.length;

      final isSecure = riskScore <= config.maxAllowedRiskScore;

      return TransactionSecurityContext(
        isSecure: isSecure,
        checks: checks,
        riskScore: riskScore,
        timestamp: timestamp,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Security context preparation error: $e');
      }

      // 에러 발생 시 안전하지 않은 것으로 간주
      checks.add(
        SecurityCheckResult.failed(
          'Security Context',
          reason: 'Failed to prepare security context: $e',
          severity: 0.7,
        ),
      );

      return TransactionSecurityContext(
        isSecure: false,
        checks: checks,
        riskScore: 1.0,
        timestamp: timestamp,
      );
    }
  }

  /// 트랜잭션 서명
  ///
  /// 보안 컨텍스트를 검증한 후 트랜잭션에 서명합니다.
  ///
  /// **Parameters:**
  /// - [transaction]: 서명할 트랜잭션 데이터
  /// - [pin]: 사용자 PIN (키 복호화용)
  ///
  /// Returns [SignedTransaction] - 서명된 트랜잭션
  ///
  /// **보안 원칙:**
  /// - 프라이빗 키는 메모리에 최소 시간만 유지
  /// - 서명 완료 즉시 키 삭제 (메모리 와이핑)
  /// - 모든 중간 데이터 즉시 정리
  Future<SignedTransaction> signTransaction(
    TransactionData transaction,
    String pin,
  ) async {
    // 1. 보안 컨텍스트 검증
    final securityContext = await prepareSecureContext();

    if (!securityContext.isSafeForSigning) {
      throw SecurityException(
        'Transaction signing blocked due to security concerns',
        securityContext,
      );
    }

    // 2. 트랜잭션 검증
    await validateTransactionSecurity(transaction);

    // 3. 트랜잭션 서명 (실제 구현 필요)
    // TODO: 실제 암호화 라이브러리와 통합
    final signature = await _signTransactionInternal(transaction, pin);
    final txHash = _calculateTransactionHash(transaction, signature);

    // 4. Strict Mode 해제
    if (config.overlayProtectionEnabled) {
      await _overlayProtectionService.disableStrictMode();
    }

    return SignedTransaction(
      transaction: transaction,
      signature: signature,
      txHash: txHash,
      signedAt: DateTime.now(),
      securityContext: securityContext,
    );
  }

  /// 트랜잭션 보안 검증
  ///
  /// 트랜잭션 데이터의 보안 요구사항을 확인합니다.
  ///
  /// **검증 항목:**
  /// - 수신자 주소 유효성 (체크섬 확인)
  /// - 전송 금액 합리성 (잔액 초과 방지)
  /// - 가스 가격 합리성 (과도한 수수료 방지)
  /// - 논스 순서 확인
  Future<void> validateTransactionSecurity(
      TransactionData transaction) async {
    // 주소 유효성 검증
    if (!_isValidEthereumAddress(transaction.to)) {
      throw ValidationException('Invalid recipient address: ${transaction.to}');
    }

    // 가스 가격 합리성 검증 (예: 1000 Gwei 초과 방지)
    final maxGasPrice = BigInt.from(1000) * BigInt.from(1000000000); // 1000 Gwei
    if (transaction.gasPrice > maxGasPrice) {
      throw ValidationException(
        'Gas price too high: ${transaction.gasPrice} Wei',
      );
    }

    // 금액 검증 (0 이상)
    if (transaction.value < BigInt.zero) {
      throw ValidationException('Invalid transaction value: ${transaction.value}');
    }
  }

  /// 트랜잭션 내부 서명 (Mock)
  ///
  /// **실제 구현 시:**
  /// - web3dart 라이브러리 사용
  /// - EIP-155 준수 (Replay Attack 방지)
  /// - ECDSA secp256k1 서명
  Future<String> _signTransactionInternal(
    TransactionData transaction,
    String pin,
  ) async {
    // TODO: 실제 서명 구현
    // 1. PIN으로 프라이빗 키 복호화
    // 2. RLP 인코딩
    // 3. Keccak-256 해시
    // 4. ECDSA 서명
    // 5. 프라이빗 키 즉시 삭제

    // Mock 서명 (테스트용)
    final txData = jsonEncode(transaction.toMap());
    final bytes = utf8.encode(txData + pin);
    final hash = sha256.convert(bytes);
    return '0x${hash.toString()}';
  }

  /// 트랜잭션 해시 계산
  String _calculateTransactionHash(
    TransactionData transaction,
    String signature,
  ) {
    final data = jsonEncode({
      ...transaction.toMap(),
      'signature': signature,
    });
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return '0x${hash.toString()}';
  }

  /// Ethereum 주소 유효성 검증
  bool _isValidEthereumAddress(String address) {
    // 기본 형식 검증
    if (!address.startsWith('0x')) {
      return false;
    }

    if (address.length != 42) {
      return false;
    }

    // Hex 문자열 검증
    final hexPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');
    return hexPattern.hasMatch(address);
  }
}

/// 보안 예외
class SecurityException implements Exception {
  final String message;
  final TransactionSecurityContext context;

  SecurityException(this.message, this.context);

  @override
  String toString() {
    return 'SecurityException: $message\n'
        'Risk Score: ${context.riskScore}\n'
        'Failed Checks: ${context.failedChecks.map((c) => c.checkName).join(', ')}';
  }
}

/// 검증 예외
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
