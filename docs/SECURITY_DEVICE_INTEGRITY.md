# Device Integrity Detection (루팅/탈옥 감지)

## 개요

암호화폐 지갑 앱의 보안을 강화하기 위한 Defense-in-Depth 전략 기반의 루팅/탈옥 감지 시스템입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter Layer                          │
├─────────────────────────────────────────────────────────────┤
│  DeviceIntegrityService                                       │
│  ├─ checkDeviceIntegrity() → DeviceIntegrityResult          │
│  ├─ quickCheck() → bool                                      │
│  └─ Platform detection (Android/iOS)                         │
├─────────────────────────────────────────────────────────────┤
│                    MethodChannel Bridge                       │
│        com.etherflow.crypto_wallet_pro/security              │
├─────────────────────────────────────────────────────────────┤
│                      Native Layer                             │
├─────────────────────────────────────────────────────────────┤
│  Android (Kotlin)              │  iOS (Swift)                 │
│  ├─ checkRootStatus()          │  ├─ checkJailbreakStatus()  │
│  ├─ 5-Layer Detection          │  └─ 5-Layer Detection       │
│  └─ Returns Map<String, Any>   │                              │
└─────────────────────────────────────────────────────────────┘
```

## Android 루팅 감지 (5계층)

### Layer 1: su 바이너리 검사 (가중치: 0.4)
- **목적**: 루팅 도구의 핵심 파일 탐지
- **검사 경로**:
  ```
  /system/bin/su
  /system/xbin/su
  /system/sbin/su
  /sbin/su
  /su/bin/su
  /magisk/.core/bin/su
  /system/usr/we-need-root/su
  /data/local/su
  /data/local/bin/su
  /data/local/xbin/su
  ```
- **검증 방식**: `File.exists()` + `File.canExecute()`

### Layer 2: Superuser 앱 패키지 검사 (가중치: 0.3)
- **목적**: 루팅 관리 앱 탐지
- **대상 패키지**:
  - Magisk Manager (`com.topjohnwu.magisk`)
  - SuperSU (`eu.chainfire.supersu`)
  - KingRoot (`com.kingroot.kinguser`)
  - 기타 12개 주요 루팅 도구
- **검증 방식**: `PackageManager.getPackageInfo()`

### Layer 3: 빌드 태그 검사 (가중치: 0.2)
- **목적**: 비공식 ROM 감지
- **검사 항목**: `Build.TAGS`에 "test-keys" 포함 여부
- **정상 기기**: "release-keys"로 서명됨

### Layer 4: 위험 경로 쓰기 권한 (가중치: 0.15)
- **목적**: 시스템 디렉토리 무결성 확인
- **검사 경로**: `/system`, `/vendor/bin`, `/sbin` 등
- **정상 기기**: 읽기 전용 (쓰기 불가)

### Layer 5: SELinux 상태 (가중치: 0.15)
- **목적**: 보안 정책 우회 탐지
- **검사 명령**: `getenforce`
- **위험 상태**: Permissive 모드

### 위험도 계산
```kotlin
riskScore =
  (Layer1 * 0.4) +
  (Layer2 * 0.3) +
  (Layer3 * 0.2) +
  (Layer4 * 0.15) +
  (Layer5 * 0.15)

isRooted = riskScore >= 0.3 (30%)
```

## iOS 탈옥 감지 (5계층)

### Layer 1: 탈옥 앱 존재 여부 (가중치: 0.4)
- **목적**: 탈옥 패키지 관리자 탐지
- **검사 앱**:
  ```swift
  /Applications/Cydia.app
  /Applications/Sileo.app
  /Applications/Zebra.app
  /Applications/blackra1n.app
  /Applications/WinterBoard.app
  ```
- **검증 방식**: `FileManager.fileExists(atPath:)`

### Layer 2: 탈옥 파일 경로 접근 (가중치: 0.3)
- **목적**: 샌드박스 무결성 확인
- **검사 경로**:
  ```swift
  /private/var/lib/apt/
  /private/var/lib/cydia
  /usr/sbin/sshd
  /bin/bash
  /etc/apt
  /Library/MobileSubstrate/MobileSubstrate.dylib
  ```
- **정상 기기**: 샌드박스로 인해 접근 불가

### Layer 3: 샌드박스 무결성 검사 (가중치: 0.25)
- **목적**: fork() 호출 가능 여부 확인
- **검증 방식**: `dlsym(RTLD_DEFAULT, "fork")`
- **정상 기기**: fork 심볼 없음
- **탈옥 기기**: fork 심볼 존재

### Layer 4: 심볼릭 링크 검사 (가중치: 0.15)
- **목적**: 시스템 파일 구조 변조 탐지
- **검사 경로**: `/Applications`, `/Library/Ringtones` 등
- **정상 기기**: 특정 심볼릭 링크 없음

### Layer 5: 동적 라이브러리 검사 (가중치: 0.2)
- **목적**: 탈옥 트윅 프레임워크 탐지
- **대상 라이브러리**:
  - MobileSubstrate
  - Substitute
  - TweakInject
- **검증 방식**: `_dyld_image_count()` + `_dyld_get_image_name()`

### 위험도 계산
```swift
riskScore =
  (Layer1 * 0.4) +
  (Layer2 * 0.3) +
  (Layer3 * 0.25) +
  (Layer4 * 0.15) +
  (Layer5 * 0.2)

isJailbroken = riskScore >= 0.3 (30%)
```

## Flutter 통합

### DeviceIntegrityService 사용법

```dart
import 'package:crypto_wallet_pro/core/security/services/device_integrity_service.dart';

final service = DeviceIntegrityService();

// 종합 검사
final result = await service.checkDeviceIntegrity();

if (result.isCompromised) {
  print('위험도: ${(result.riskLevel * 100).toInt()}%');
  print('감지된 위험 요소:');
  for (final threat in result.details) {
    print('- $threat');
  }
}

// 빠른 검사 (경량 버전)
final isCompromised = await service.quickCheck();
```

### DeviceIntegrityResult 구조

```dart
class DeviceIntegrityResult {
  final DeviceIntegrityStatus status; // secure, rooted, jailbroken, unknown
  final List<String> details;          // 감지된 위험 요소 목록
  final double riskLevel;              // 0.0 ~ 1.0

  bool get isSecure;                   // status == secure
  bool get isCompromised;              // rooted || jailbroken
}
```

### 앱 시작 시 자동 검사

`main.dart`에서 `CryptoWalletApp` 위젯이 초기화될 때 자동으로 검사를 수행하고, 위험 감지 시 경고 다이얼로그를 표시합니다.

```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkDeviceIntegrity();
  });
}
```

### 경고 다이얼로그

```dart
import 'package:crypto_wallet_pro/core/security/widgets/integrity_warning_dialog.dart';

final shouldContinue = await showIntegrityWarning(context, result);

if (shouldContinue == true) {
  // 사용자가 위험을 감수하고 계속 사용
} else {
  // 앱 종료
  SystemNavigator.pop();
}
```

## 보안 원칙

### 1. Defense-in-Depth (심층 방어)
- 단일 검사에 의존하지 않고 여러 계층의 검사 조합
- 각 계층은 독립적으로 작동하며 가중치 부여
- 한 계층이 우회되어도 다른 계층에서 탐지 가능

### 2. Graceful Degradation (우아한 성능 저하)
```dart
try {
  // 검사 수행
} catch (e) {
  // 에러 발생 시 앱 크래시 없이 unknown 반환
  return DeviceIntegrityResult(
    status: DeviceIntegrityStatus.unknown,
    details: ['검사 실패: $e'],
    riskLevel: 0.5,
  );
}
```

### 3. 사용자 선택 존중
- 루팅/탈옥된 기기에서도 경고 후 사용 가능
- 강제 차단하지 않음 (규제 요구사항 없는 한)
- 투명한 위험 정보 제공

### 4. False Positive 최소화
- 30% 위험도 임계값 설정 (너무 민감하지 않게)
- 각 검사 항목의 가중치 조정으로 정확도 향상
- Simulator/Emulator 환경 고려 (`#if targetEnvironment(simulator)`)

## 테스트

### Unit Tests
```bash
flutter test test/core/security/device_integrity_service_test.dart
```

### 테스트 커버리지
- DeviceIntegrityResult 상태별 검증
- Null safety 처리
- Edge case 처리 (빈 리스트, null 값)
- Enum 정의 검증

### Integration Tests (실제 기기 필요)
```bash
# 루팅된 Android 기기에서
flutter drive --target=integration_test/device_integrity_test.dart

# 탈옥된 iOS 기기에서
flutter drive --target=integration_test/device_integrity_test.dart
```

## 제한사항

### Android
- Magisk Hide 등 고급 은폐 기술로 우회 가능
- Play Integrity API와 병행 사용 권장 (프로덕션)

### iOS
- iOS 17+ 에서 일부 탐지 방법 변경됨
- 시뮬레이터에서는 정상적인 탐지 불가

### 공통
- 완벽한 탐지는 불가능 (cat-and-mouse game)
- 정기적인 탐지 로직 업데이트 필요

## 향후 개선 사항

### 고급 탐지 기술
1. **Play Integrity API** (Android)
   - Google Play 서비스 기반 기기 인증
   - SafetyNet Attestation 후속 API

2. **App Attest** (iOS)
   - Apple의 공식 기기 검증 API
   - iOS 14+에서 사용 가능

3. **Runtime Detection**
   - Frida, Xposed 등 동적 분석 도구 탐지
   - 디버거 연결 감지

4. **Behavioral Analysis**
   - 앱 실행 패턴 분석
   - 비정상적인 API 호출 탐지

### 모니터링 및 분석
- Firebase Crashlytics로 탐지 결과 로깅
- 탐지율 통계 수집 및 분석
- False positive 케이스 모니터링

## 참고 자료

- [RootBeer Library (Android)](https://github.com/scottyab/rootbeer)
- [iOS Jailbreak Detection](https://github.com/securing/IOSSecuritySuite)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Play Integrity API Documentation](https://developer.android.com/google/play/integrity)
- [Apple App Attest](https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server)

## 파일 구조

```
lib/core/security/
├── services/
│   ├── screenshot_protection_service.dart
│   └── device_integrity_service.dart         # 새로 추가
└── widgets/
    ├── secure_content_wrapper.dart
    └── integrity_warning_dialog.dart          # 새로 추가

android/app/src/main/kotlin/com/etherflow/crypto_wallet_pro/
└── MainActivity.kt                             # 루팅 감지 로직 추가

ios/Runner/
└── AppDelegate.swift                           # 탈옥 감지 로직 추가

test/core/security/
└── device_integrity_service_test.dart         # 새로 추가
```

## 라이선스

이 코드는 프로젝트의 기존 라이선스를 따릅니다.
