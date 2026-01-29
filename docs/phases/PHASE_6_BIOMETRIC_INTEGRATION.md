# Phase 6: 생체인증 통합 구현

## 개요

Phase 6에서는 생체인증(지문/Face ID)과 Phase 5의 암호화 시스템을 통합하여 사용자가 생체인증만으로 암호화된 민감 데이터에 안전하게 접근할 수 있도록 구현했습니다.

## 구현 내용

### 1. 플랫폼 설정

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSFaceIDUsageDescription</key>
<string>지갑 보안을 위해 Face ID가 필요합니다.</string>
```

### 2. 핵심 서비스

#### 2.1 EnhancedBiometricService
`lib/core/security/services/enhanced_biometric_service.dart`

기존 `BiometricService`를 확장하여 다음 기능을 추가:
- 사용 가능한 생체인증 유형 조회 (Face ID, Touch ID, 지문 등)
- 세션 관리 (3분 유효 기간)
- 강제 재인증 옵션 (`forceAuth`)
- 주 생체인증 유형 자동 감지

**주요 메서드:**
```dart
Future<bool> canCheck()                           // 생체인증 가능 여부
Future<List<BiometricType>> getAvailableBiometrics()  // 사용 가능한 유형
Future<bool> authenticate({String reason})        // 생체인증 수행
Future<bool> ensureAuthenticated({bool forceAuth}) // 세션 또는 재인증
Future<BiometricType?> getPrimaryBiometricType()  // 주 인증 유형
void invalidateSession()                          // 세션 무효화
```

#### 2.2 BiometricKeyService
`lib/core/security/services/biometric_key_service.dart`

생체인증 보호 키 관리 서비스 (핵심 보안 로직).

**아키텍처 (2계층 보안):**
```
┌──────────────────────────────────────────────────────────────┐
│                  Biometric-Protected Key Flow                │
├──────────────────────────────────────────────────────────────┤
│ [PIN 설정 시]                                                 │
│ 1. User PIN → PBKDF2 → PIN-based Key                         │
│ 2. Generate Random Biometric Key (32 bytes)                  │
│ 3. PIN-based Key encrypts Biometric Key                      │
│ 4. Encrypted Biometric Key → Secure Storage                  │
│ 5. Biometric Key → Platform Keystore (생체인증 보호)          │
├──────────────────────────────────────────────────────────────┤
│ [생체인증으로 접근 시]                                         │
│ 1. Biometric Auth → 성공                                      │
│ 2. Biometric Key → Secure Storage에서 조회                    │
│ 3. Biometric Key → 니모닉 복호화에 사용                        │
├──────────────────────────────────────────────────────────────┤
│ [PIN으로 접근 시 (폴백)]                                       │
│ 1. User PIN → PBKDF2 → PIN-based Key                         │
│ 2. PIN-based Key decrypts Encrypted Biometric Key            │
│ 3. Biometric Key → 니모닉 복호화에 사용                        │
└──────────────────────────────────────────────────────────────┘
```

**주요 메서드:**
```dart
Future<void> generateAndSaveBiometricKey({String pin})    // 키 생성 및 저장
Future<String?> getBiometricKey({String reason})          // 생체인증으로 조회
Future<String?> getBiometricKeyWithPin({String pin})      // PIN으로 조회 (폴백)
Future<String> encryptWithBiometricKey({...})             // 데이터 암호화
Future<String> decryptWithBiometricKey({...})             // 데이터 복호화
Future<void> changePinForBiometricKey({...})              // PIN 변경 시 재암호화
Future<void> deleteBiometricKey()                         // 키 삭제
Future<bool> isBiometricKeyAvailable()                    // 키 존재 여부
```

**보안 특성:**
- CSPRNG 기반 키 생성 (FortunaRandom)
- AES-256-GCM 암호화 (Phase 5 EncryptionService 재사용)
- PBKDF2-SHA256 키 파생 (100,000 iterations)
- Android Keystore / iOS Keychain 플랫폼 보안

### 3. Riverpod Providers
`lib/core/security/providers/biometric_key_providers.dart`

```dart
enhancedBiometricServiceProvider       // EnhancedBiometricService 인스턴스
encryptionServiceProvider              // EncryptionService 인스턴스
keyDerivationServiceProvider           // KeyDerivationService 인스턴스
biometricKeyServiceProvider            // BiometricKeyService 인스턴스

canUseBiometricsProvider               // 생체인증 가능 여부 (FutureProvider)
availableBiometricsProvider            // 사용 가능한 생체인증 유형
hasBiometricKeyProvider                // 생체인증 키 존재 여부
primaryBiometricTypeProvider           // 주 생체인증 유형
```

### 4. Storage Keys
`lib/core/constants/storage_keys.dart`

Phase 6에서 추가된 키:
```dart
static const String biometricKey = 'wallet_biometric_key';
static const String encryptedBiometricKey = 'wallet_encrypted_biometric_key';
static const String biometricKeySalt = 'wallet_biometric_key_salt';
```

## 보안 요구사항

### 1. 키 생성
- **CSPRNG**: FortunaRandom 사용
- **키 길이**: 256비트 (32바이트)
- **엔트로피**: Random.secure()로 시드 초기화

### 2. 암호화
- **알고리즘**: AES-256-GCM (Phase 5 재사용)
- **IV**: 12바이트 랜덤 (매번 새로 생성)
- **Tag**: 128비트 (변조 방지)

### 3. 키 파생
- **알고리즘**: PBKDF2-SHA256 (Phase 5 재사용)
- **Iterations**: 100,000
- **Salt**: 32바이트 랜덤

### 4. 플랫폼 보안
- **Android**: Android Keystore
- **iOS**: iOS Keychain
- **플러터**: Flutter Secure Storage로 래핑

## 단위 테스트

### EnhancedBiometricService 테스트
`test/core/security/enhanced_biometric_service_test.dart`

**테스트 커버리지:**
- ✅ 생체인증 가능 여부 확인 (하드웨어 + 등록)
- ✅ 사용 가능한 생체인증 유형 조회
- ✅ 생체인증 성공/실패 시나리오
- ✅ 세션 관리 (유효/만료)
- ✅ 강제 재인증 (`forceAuth`)
- ✅ 세션 무효화
- ✅ 주 생체인증 유형 감지 (Face ID > 지문 > 홍채)
- ✅ 생체인증 유형별 한국어 이름 반환

**테스트 결과:**
```
00:00 +18: All tests passed!
```

### BiometricKeyService 테스트
`test/core/security/biometric_key_service_test.dart`

**테스트 커버리지:**
- ✅ 생체인증 키 존재 여부 확인
- ✅ 생체인증 키 생성 및 저장
- ✅ 기존 Salt 재사용
- ✅ 생체인증으로 키 조회 (성공/실패)
- ✅ PIN으로 키 복호화 (폴백)
- ✅ 잘못된 PIN으로 복호화 시 예외 발생
- ✅ 암호화된 키 또는 Salt 없을 때 처리
- ✅ 생체인증 키로 데이터 암호화/복호화
- ✅ PIN 폴백 암호화
- ✅ PIN 변경 시 재암호화
- ✅ 잘못된 기존 PIN으로 변경 시 예외
- ✅ 모든 생체인증 키 데이터 삭제

**테스트 결과:**
```
00:04 +15: All tests passed!
```

## 사용 예시

### 1. 생체인증 키 생성
```dart
final biometricKeyService = ref.read(biometricKeyServiceProvider);

// 지갑 생성 시 생체인증 키도 함께 생성
await biometricKeyService.generateAndSaveBiometricKey(
  pin: userPin,
);
```

### 2. 생체인증으로 니모닉 복호화
```dart
final biometricKeyService = ref.read(biometricKeyServiceProvider);

// 생체인증으로 니모닉 복호화
final mnemonic = await biometricKeyService.decryptWithBiometricKey(
  ciphertext: encryptedMnemonic,
  pin: userPin,          // 폴백용
  useBiometric: true,    // 생체인증 우선
);
```

### 3. PIN 변경 시 재암호화
```dart
final biometricKeyService = ref.read(biometricKeyServiceProvider);

// PIN 변경 시 생체인증 키도 새로운 PIN으로 재암호화
await biometricKeyService.changePinForBiometricKey(
  oldPin: currentPin,
  newPin: newPin,
);
```

### 4. UI에서 생체인증 유형 표시
```dart
class BiometricSettingsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryType = ref.watch(primaryBiometricTypeProvider);

    return primaryType.when(
      data: (type) {
        if (type == BiometricType.face) {
          return Row(
            children: [
              Icon(Icons.face),
              Text('Face ID로 잠금 해제'),
            ],
          );
        } else if (type == BiometricType.fingerprint) {
          return Row(
            children: [
              Icon(Icons.fingerprint),
              Text('지문으로 잠금 해제'),
            ],
          );
        }
        return Text('생체인증 사용 불가');
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('오류: $err'),
    );
  }
}
```

## 파일 구조

```
lib/core/
├── constants/
│   └── storage_keys.dart                    # [수정] 생체인증 키 상수 추가
├── security/
│   ├── services/
│   │   ├── enhanced_biometric_service.dart  # [신규] 향상된 생체인증
│   │   ├── biometric_key_service.dart       # [신규] 생체인증 키 관리
│   │   ├── encryption_service.dart          # [기존] Phase 5
│   │   └── key_derivation_service.dart      # [기존] Phase 5
│   └── providers/
│       └── biometric_key_providers.dart     # [신규] Riverpod 프로바이더

test/core/security/
├── enhanced_biometric_service_test.dart     # [신규] 18개 테스트
├── biometric_key_service_test.dart          # [신규] 15개 테스트
└── ...

android/app/src/main/
└── AndroidManifest.xml                      # [수정] 생체인증 권한

ios/Runner/
└── Info.plist                               # [수정] Face ID 권한
```

## 통합 테스트 결과

```bash
# EnhancedBiometricService 테스트
flutter test test/core/security/enhanced_biometric_service_test.dart
# 결과: All tests passed! (18개)

# BiometricKeyService 테스트
flutter test test/core/security/biometric_key_service_test.dart
# 결과: All tests passed! (15개)

# 전체 보안 테스트
flutter test test/core/security/
# 결과: 전체 통과
```

## 위협 모델 대응

| 위협 | 심각도 | Phase 6 대응 |
|------|--------|------------|
| 물리적 접근 | 높음 | 생체인증 + 플랫폼 암호화 (Keystore/Keychain) |
| 멀웨어 | 높음 | 이중 암호화 + 생체인증 세션 관리 |
| 무차별 대입 공격 | 중간 | PBKDF2 100,000 iterations + PIN 폴백 |
| 중간자 공격 | 낮음 | 로컬 저장소만 사용 (네트워크 전송 없음) |
| 메모리 덤프 | 높음 | 세션 기반 접근 + 즉시 삭제 |

## 보안 체크리스트

- [x] 프라이빗 키 평문 저장 금지
- [x] 시드 구문 화면 캡처 방지 (플랫폼 설정)
- [x] 생체인증 키 암호화 저장
- [x] PIN 폴백 메커니즘 구현
- [x] 세션 관리 (3분 타임아웃)
- [x] 키 파생 알고리즘 검증 (PBKDF2)
- [x] 암호화 알고리즘 검증 (AES-256-GCM)
- [x] 단위 테스트 작성 (33개)

## 다음 단계 (Phase 7 권장)

1. **EncryptedStorageService 통합**: 생체인증 키로 니모닉 암호화/복호화
2. **UI 구현**: 생체인증 설정 화면 추가
3. **지갑 생성/가져오기 통합**: 생체인증 키 자동 생성
4. **트랜잭션 서명 통합**: 서명 시 생체인증 요청
5. **설정 화면**: 생체인증 활성화/비활성화 토글

## 참고 자료

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Local Auth](https://pub.dev/packages/local_auth)
- [PointyCastle](https://pub.dev/packages/pointycastle)
- [Android Keystore](https://developer.android.com/training/articles/keystore)
- [iOS Keychain](https://developer.apple.com/documentation/security/keychain_services)
