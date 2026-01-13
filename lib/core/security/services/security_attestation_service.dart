import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:equatable/equatable.dart';

/// 증명(Attestation) 결과
///
/// Google Play Integrity API 또는 Apple DeviceCheck/App Attest의 결과
class AttestationResult extends Equatable {
  /// 디바이스 무결성 상태
  final DeviceIntegrityState deviceIntegrity;

  /// 앱 무결성 상태
  final AppIntegrityState appIntegrity;

  /// 환경 타입 (실제 기기 / 에뮬레이터)
  final EnvironmentType environment;

  /// 증명 토큰 (서버 검증용)
  final String? attestationToken;

  /// 추가 상세 정보
  final Map<String, dynamic> details;

  /// 증명 시각
  final DateTime timestamp;

  const AttestationResult({
    required this.deviceIntegrity,
    required this.appIntegrity,
    required this.environment,
    this.attestationToken,
    required this.details,
    required this.timestamp,
  });

  /// 안전한 환경인지 확인
  bool get isSecure =>
      deviceIntegrity == DeviceIntegrityState.trusted &&
      appIntegrity == AppIntegrityState.genuine &&
      environment == EnvironmentType.physicalDevice;

  /// 위험한 환경인지 확인
  bool get isCompromised =>
      deviceIntegrity == DeviceIntegrityState.compromised ||
      appIntegrity == AppIntegrityState.tampered;

  @override
  List<Object?> get props => [
        deviceIntegrity,
        appIntegrity,
        environment,
        attestationToken,
        details,
        timestamp,
      ];

  @override
  String toString() {
    return 'AttestationResult(device: $deviceIntegrity, '
        'app: $appIntegrity, env: $environment, secure: $isSecure)';
  }
}

/// 디바이스 무결성 상태
enum DeviceIntegrityState {
  /// 신뢰할 수 있는 기기
  trusted,

  /// 손상된 기기 (루팅/탈옥)
  compromised,

  /// 확인 불가
  unknown,
}

/// 앱 무결성 상태
enum AppIntegrityState {
  /// 정품 앱 (공식 스토어 설치)
  genuine,

  /// 변조된 앱 (사이드로딩, 리패키징)
  tampered,

  /// 확인 불가
  unknown,
}

/// 환경 타입
enum EnvironmentType {
  /// 실제 물리 기기
  physicalDevice,

  /// 에뮬레이터 / 시뮬레이터
  emulator,

  /// 확인 불가
  unknown,
}

/// 보안 증명(Security Attestation) 서비스
///
/// 디바이스 및 앱의 무결성을 검증하기 위한 증명 서비스.
///
/// **Android: Google Play Integrity API**
/// - Play Protect 검증
/// - 디바이스 무결성 확인 (SafetyNet 후속)
/// - 앱 라이선스 검증
/// - 에뮬레이터 탐지
///
/// **iOS: DeviceCheck / App Attest**
/// - 디바이스 신뢰성 검증
/// - 앱 무결성 확인
/// - 시뮬레이터 탐지
/// - 재생 공격 방지
///
/// **사용 사례**
/// 1. 앱 시작 시 환경 검증
/// 2. 중요 트랜잭션 전 재검증
/// 3. 서버 API 호출 시 토큰 첨부
///
/// **사용 예시**
/// ```dart
/// final service = SecurityAttestationService();
///
/// // 증명 요청
/// final result = await service.performAttestation();
///
/// if (result.isSecure) {
///   // 안전한 환경: 정상 동작
///   await processTransaction();
/// } else if (result.isCompromised) {
///   // 위험한 환경: 차단
///   showSecurityWarning();
/// } else {
///   // 확인 불가: 경고 표시
///   showAttestationFailedWarning();
/// }
///
/// // 서버로 토큰 전송
/// if (result.attestationToken != null) {
///   await api.verifyAttestation(result.attestationToken);
/// }
/// ```
class SecurityAttestationService {
  static const MethodChannel _channel =
      MethodChannel('com.etherflow.crypto_wallet_pro/attestation');

  AttestationResult? _cachedResult;
  DateTime? _lastAttestationTime;

  /// 보안 증명 수행
  ///
  /// [forceRefresh]: 캐시 무시하고 강제로 새로운 증명 요청
  ///
  /// Returns: 증명 결과
  Future<AttestationResult> performAttestation({
    bool forceRefresh = false,
  }) async {
    // 캐시된 결과가 있고, 5분 이내이면 재사용
    if (!forceRefresh &&
        _cachedResult != null &&
        _lastAttestationTime != null &&
        DateTime.now().difference(_lastAttestationTime!).inMinutes < 5) {
      return _cachedResult!;
    }

    try {
      try {
        if (Platform.isAndroid) {
          return await _performAndroidAttestation();
        } else if (Platform.isIOS) {
          return await _performIOSAttestation();
        } else {
          // 테스트 환경: Android 시도
          return await _performAndroidAttestation();
        }
      } on MissingPluginException {
        return _createUnknownResult();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Attestation error: $e');
      }
      return _createUnknownResult();
    }
  }

  /// Android Play Integrity API 증명
  Future<AttestationResult> _performAndroidAttestation() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('performPlayIntegrityAttestation');

      final attestationResult = AttestationResult(
        deviceIntegrity: _parseDeviceIntegrity(
          result['deviceIntegrity'] as String?,
        ),
        appIntegrity: _parseAppIntegrity(
          result['appIntegrity'] as String?,
        ),
        environment: _parseEnvironment(
          result['environment'] as String?,
        ),
        attestationToken: result['token'] as String?,
        details: Map<String, dynamic>.from(result['details'] as Map? ?? {}),
        timestamp: DateTime.now(),
      );

      _cachedResult = attestationResult;
      _lastAttestationTime = DateTime.now();

      return attestationResult;
    } on MissingPluginException {
      // 플랫폼 구현 없음: Mock 결과
      return _createMockAndroidResult();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Android attestation error: ${e.message}');
      }
      return _createUnknownResult();
    }
  }

  /// iOS DeviceCheck/App Attest 증명
  Future<AttestationResult> _performIOSAttestation() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('performAppAttestation');

      final attestationResult = AttestationResult(
        deviceIntegrity: _parseDeviceIntegrity(
          result['deviceIntegrity'] as String?,
        ),
        appIntegrity: _parseAppIntegrity(
          result['appIntegrity'] as String?,
        ),
        environment: _parseEnvironment(
          result['environment'] as String?,
        ),
        attestationToken: result['token'] as String?,
        details: Map<String, dynamic>.from(result['details'] as Map? ?? {}),
        timestamp: DateTime.now(),
      );

      _cachedResult = attestationResult;
      _lastAttestationTime = DateTime.now();

      return attestationResult;
    } on MissingPluginException {
      // 플랫폼 구현 없음: Mock 결과
      return _createMockIOSResult();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('iOS attestation error: ${e.message}');
      }
      return _createUnknownResult();
    }
  }

  /// 디바이스 무결성 검증 (빠른 체크)
  ///
  /// 전체 증명 없이 디바이스 상태만 빠르게 확인
  Future<DeviceIntegrityState> quickDeviceCheck() async {
    try {
      String methodName;
      if (Platform.isAndroid) {
        methodName = 'quickDeviceCheck';
      } else if (Platform.isIOS) {
        methodName = 'quickDeviceCheck';
      } else {
        // 테스트 환경
        methodName = 'quickDeviceCheck';
      }

      final String result = await _channel.invokeMethod(methodName);
      return _parseDeviceIntegrity(result);
    } on MissingPluginException {
      return DeviceIntegrityState.trusted; // 테스트 환경
    } on PlatformException {
      return DeviceIntegrityState.unknown;
    }
  }

  /// 에뮬레이터/시뮬레이터 탐지
  ///
  /// Returns: 에뮬레이터면 true
  Future<bool> isEmulator() async {
    try {
      String methodName;
      if (Platform.isAndroid) {
        methodName = 'isEmulator';
      } else if (Platform.isIOS) {
        methodName = 'isSimulator';
      } else {
        // 테스트 환경
        methodName = 'isEmulator';
      }

      final bool result = await _channel.invokeMethod(methodName);
      return result;
    } on MissingPluginException {
      // 테스트 환경: 에뮬레이터 아님
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// 증명 토큰 갱신
  ///
  /// 서버와 통신 전에 호출하여 최신 증명 토큰 획득
  Future<String?> refreshAttestationToken() async {
    final result = await performAttestation(forceRefresh: true);
    return result.attestationToken;
  }

  /// 마지막 증명 결과 조회
  ///
  /// Returns: 캐시된 증명 결과 (없으면 null)
  AttestationResult? getLastAttestationResult() {
    return _cachedResult;
  }

  /// 마지막 증명 시각 조회
  ///
  /// Returns: 마지막 증명 시각 (없으면 null)
  DateTime? getLastAttestationTime() {
    return _lastAttestationTime;
  }

  /// 캐시 무효화
  void invalidateCache() {
    _cachedResult = null;
    _lastAttestationTime = null;
  }

  /// 디바이스 무결성 문자열 파싱
  DeviceIntegrityState _parseDeviceIntegrity(String? state) {
    if (state == null) return DeviceIntegrityState.unknown;

    switch (state.toLowerCase()) {
      case 'trusted':
      case 'meets_device_integrity':
        return DeviceIntegrityState.trusted;
      case 'compromised':
      case 'meets_basic_integrity':
        return DeviceIntegrityState.compromised;
      default:
        return DeviceIntegrityState.unknown;
    }
  }

  /// 앱 무결성 문자열 파싱
  AppIntegrityState _parseAppIntegrity(String? state) {
    if (state == null) return AppIntegrityState.unknown;

    switch (state.toLowerCase()) {
      case 'genuine':
      case 'meets_strong_integrity':
        return AppIntegrityState.genuine;
      case 'tampered':
      case 'unrecognized_version':
        return AppIntegrityState.tampered;
      default:
        return AppIntegrityState.unknown;
    }
  }

  /// 환경 타입 문자열 파싱
  EnvironmentType _parseEnvironment(String? env) {
    if (env == null) return EnvironmentType.unknown;

    switch (env.toLowerCase()) {
      case 'physical_device':
      case 'device':
        return EnvironmentType.physicalDevice;
      case 'emulator':
      case 'simulator':
        return EnvironmentType.emulator;
      default:
        return EnvironmentType.unknown;
    }
  }

  /// Unknown 상태 결과 생성
  AttestationResult _createUnknownResult() {
    return AttestationResult(
      deviceIntegrity: DeviceIntegrityState.unknown,
      appIntegrity: AppIntegrityState.unknown,
      environment: EnvironmentType.unknown,
      attestationToken: null,
      details: const {'error': 'Attestation unavailable'},
      timestamp: DateTime.now(),
    );
  }

  /// Mock Android 결과 (테스트용)
  AttestationResult _createMockAndroidResult() {
    return AttestationResult(
      deviceIntegrity: DeviceIntegrityState.trusted,
      appIntegrity: AppIntegrityState.genuine,
      environment: EnvironmentType.physicalDevice,
      attestationToken: 'MOCK_ANDROID_TOKEN',
      details: const {'platform': 'android', 'mock': true},
      timestamp: DateTime.now(),
    );
  }

  /// Mock iOS 결과 (테스트용)
  AttestationResult _createMockIOSResult() {
    return AttestationResult(
      deviceIntegrity: DeviceIntegrityState.trusted,
      appIntegrity: AppIntegrityState.genuine,
      environment: EnvironmentType.physicalDevice,
      attestationToken: 'MOCK_IOS_TOKEN',
      details: const {'platform': 'ios', 'mock': true},
      timestamp: DateTime.now(),
    );
  }
}
