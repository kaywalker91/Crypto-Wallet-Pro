import 'package:local_auth/local_auth.dart';

/// 향상된 생체인증 서비스.
///
/// 기존 BiometricService를 확장하여 다음 기능을 추가합니다:
/// - 사용 가능한 생체인증 유형 조회 (Face ID, Touch ID, 지문 등)
/// - 세션 관리 (3분 유효 기간)
/// - 강제 재인증 옵션
///
/// **지원 생체인증 유형:**
/// - iOS: Face ID, Touch ID
/// - Android: 지문, 얼굴 인식, 홍채 인식
///
/// **사용 예시:**
/// ```dart
/// final service = EnhancedBiometricService(LocalAuthentication());
///
/// // 생체인증 가능 여부 확인
/// final canAuth = await service.canCheck();
///
/// // 사용 가능한 생체인증 유형 조회
/// final types = await service.getAvailableBiometrics();
/// if (types.contains(BiometricType.face)) {
///   print('Face ID 사용 가능');
/// }
///
/// // 생체인증 수행
/// final success = await service.authenticate(
///   reason: '지갑 잠금 해제',
/// );
/// ```
class EnhancedBiometricService {
  EnhancedBiometricService(
    this._localAuth, {
    Duration sessionDuration = const Duration(minutes: 3),
  }) : _sessionDuration = sessionDuration;

  final LocalAuthentication _localAuth;
  final Duration _sessionDuration;
  DateTime? _authSessionValidUntil;

  /// 현재 세션이 유효한지 확인합니다.
  ///
  /// **반환값:**
  /// - `true`: 세션이 유효함 (재인증 불필요)
  /// - `false`: 세션이 만료됨 (재인증 필요)
  bool get hasValidSession =>
      _authSessionValidUntil != null &&
      DateTime.now().isBefore(_authSessionValidUntil!);

  /// 디바이스가 생체인증을 지원하는지 확인합니다.
  ///
  /// **반환값:**
  /// - `true`: 하드웨어 지원 + 생체정보 등록됨
  /// - `false`: 지원 안 함 또는 생체정보 미등록
  Future<bool> canCheck() async {
    final isSupported = await _localAuth.isDeviceSupported();
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    return isSupported && canCheckBiometrics;
  }

  /// 사용 가능한 생체인증 유형을 조회합니다.
  ///
  /// **반환값:**
  /// - 사용 가능한 생체인증 유형 리스트
  ///
  /// **가능한 유형:**
  /// - `BiometricType.face`: Face ID (iOS), 얼굴 인식 (Android)
  /// - `BiometricType.fingerprint`: Touch ID (iOS), 지문 (Android)
  /// - `BiometricType.iris`: 홍채 인식 (일부 Android 기기)
  /// - `BiometricType.weak`: 낮은 보안 수준 생체인증
  /// - `BiometricType.strong`: 높은 보안 수준 생체인증
  ///
  /// **예시:**
  /// ```dart
  /// final types = await service.getAvailableBiometrics();
  /// if (types.contains(BiometricType.face)) {
  ///   print('Face ID 사용 가능');
  /// } else if (types.contains(BiometricType.fingerprint)) {
  ///   print('지문 인식 사용 가능');
  /// }
  /// ```
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 세션 만료 시간을 수동으로 연장합니다.
  ///
  /// **매개변수:**
  /// - [validUntil]: 새로운 만료 시간
  ///
  /// **주의사항:**
  /// - 이 메서드는 직접 호출하기보다는 authenticate() 성공 시 자동 호출됩니다
  void extendSession(DateTime validUntil) {
    _authSessionValidUntil = validUntil;
  }

  /// 생체인증을 수행합니다.
  ///
  /// **매개변수:**
  /// - [reason]: 사용자에게 표시할 인증 요청 메시지
  ///
  /// **반환값:**
  /// - `true`: 인증 성공
  /// - `false`: 인증 실패 또는 취소
  ///
  /// **동작:**
  /// 1. 생체인증 가능 여부 확인
  /// 2. 생체인증 프롬프트 표시
  /// 3. 성공 시 세션 시작 (3분 유효)
  ///
  /// **주의사항:**
  /// - biometricOnly: true (PIN/패턴 폴백 비활성화)
  /// - stickyAuth: true (앱 전환 시에도 인증 유지)
  Future<bool> authenticate({
    String reason = 'Authenticate to access your wallet',
  }) async {
    final canCheckBiometrics = await canCheck();
    if (!canCheckBiometrics) return false;

    final success = await _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true, // 생체인증만 허용 (PIN 폴백 비활성화)
        stickyAuth: true, // 앱 전환 시에도 인증 유지
      ),
    );

    if (success) {
      _authSessionValidUntil = DateTime.now().add(_sessionDuration);
    }

    return success;
  }

  /// 생체인증을 수행하거나 기존 세션을 확인합니다.
  ///
  /// **매개변수:**
  /// - [reason]: 사용자에게 표시할 인증 요청 메시지
  /// - [forceAuth]: `true`인 경우 세션이 유효해도 강제 재인증
  ///
  /// **반환값:**
  /// - `true`: 인증 성공 또는 유효한 세션 존재
  /// - `false`: 인증 실패
  ///
  /// **동작:**
  /// 1. [forceAuth]가 `false`이고 세션이 유효하면 즉시 `true` 반환
  /// 2. 그렇지 않으면 생체인증 수행
  ///
  /// **사용 예시:**
  /// ```dart
  /// // 일반적인 경우 (세션 재사용)
  /// final canAccess = await service.ensureAuthenticated();
  ///
  /// // 중요한 작업 (강제 재인증)
  /// final canTransfer = await service.ensureAuthenticated(
  ///   reason: '송금을 승인하려면 인증이 필요합니다',
  ///   forceAuth: true,
  /// );
  /// ```
  Future<bool> ensureAuthenticated({
    String reason = 'Authenticate to access your wallet',
    bool forceAuth = false,
  }) async {
    // 강제 재인증이 아니고 세션이 유효한 경우
    if (!forceAuth && hasValidSession) return true;

    // 생체인증 수행
    return authenticate(reason: reason);
  }

  /// 세션을 무효화합니다.
  ///
  /// **사용 사례:**
  /// - 사용자 로그아웃
  /// - 보안 설정 변경
  /// - 앱 잠금
  void invalidateSession() {
    _authSessionValidUntil = null;
  }

  /// 생체인증 유형을 사람이 읽을 수 있는 문자열로 변환합니다.
  ///
  /// **매개변수:**
  /// - [type]: 생체인증 유형
  ///
  /// **반환값:**
  /// - 한국어 설명 문자열
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID / 얼굴 인식';
      case BiometricType.fingerprint:
        return 'Touch ID / 지문 인식';
      case BiometricType.iris:
        return '홍채 인식';
      case BiometricType.weak:
        return '낮은 보안 생체인증';
      case BiometricType.strong:
        return '높은 보안 생체인증';
    }
  }

  /// 주 생체인증 유형을 조회합니다 (우선순위: 얼굴 > 지문 > 홍채).
  ///
  /// **반환값:**
  /// - 주 생체인증 유형 (없으면 `null`)
  ///
  /// **우선순위:**
  /// 1. Face ID / 얼굴 인식
  /// 2. Touch ID / 지문
  /// 3. 홍채 인식
  Future<BiometricType?> getPrimaryBiometricType() async {
    final types = await getAvailableBiometrics();
    if (types.isEmpty) return null;

    // 우선순위에 따라 반환
    if (types.contains(BiometricType.face)) return BiometricType.face;
    if (types.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    }
    if (types.contains(BiometricType.iris)) return BiometricType.iris;

    // 그 외에는 첫 번째 유형 반환
    return types.first;
  }
}
