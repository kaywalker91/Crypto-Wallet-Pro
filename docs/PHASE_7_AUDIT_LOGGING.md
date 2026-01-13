# Phase 7: Security Audit Logging

## 개요

암호화폐 지갑 앱의 보안 감사 로깅 시스템 구현. 모든 보안 관련 이벤트를 암호화하여 저장하고, 통계 분석 및 위협 탐지를 지원합니다.

## 아키텍처

### 계층 구조

```
┌─────────────────────────────────────────────────────────┐
│ Presentation Layer                                      │
│ - SecurityLogsPage (UI)                                 │
│ - AuditStatisticsWidget                                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Providers Layer                                         │
│ - securityAuditLoggerProvider                           │
│ - auditStatisticsProvider                               │
│ - recentCriticalEventsProvider                          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Service Layer                                           │
│ - SecurityAuditLogger                                   │
│   ├─ log(event, metadata)                               │
│   ├─ getLogs(filters)                                   │
│   ├─ getStatistics()                                    │
│   ├─ purgeOldLogs()                                     │
│   └─ exportLogs(pin)                                    │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Encryption   │ │ Key          │ │ Secure       │
│ Service      │ │ Derivation   │ │ Storage      │
│ (AES-256)    │ │ (PBKDF2)     │ │ (Platform)   │
└──────────────┘ └──────────────┘ └──────────────┘
```

### 데이터 흐름

```
┌──────────────┐
│ Event        │
│ Trigger      │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────┐
│ SecurityAuditLogger.log()        │
│ - Generate UUID                  │
│ - Add timestamp                  │
│ - Detect sensitive metadata      │
└──────┬───────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ AuditLogEntry                    │
│ {                                │
│   id, timestamp, eventType,      │
│   metadata, severity, category   │
│ }                                │
└──────┬───────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Append to Log Storage            │
│ - Load existing logs             │
│ - Add new entry                  │
│ - Enforce limits                 │
│ - Save as encrypted JSON         │
└──────┬───────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ SecureStorage                    │
│ (Platform Keychain/Keystore)     │
└──────────────────────────────────┘
```

## 핵심 컴포넌트

### 1. AuditEventType

보안 이벤트 유형 열거형.

**카테고리:**
- **Authentication**: 인증 관련 (생체인증, PIN)
- **Encryption**: 암호화/복호화 작업
- **Wallet**: 지갑 생성/삭제/접근
- **Transaction**: 트랜잭션 서명/전송
- **Security**: 디바이스 무결성, 위협 탐지
- **Settings**: 보안 설정 변경

**심각도:**
- **Critical**: 실패 이벤트, 민감 정보 접근, 보안 위협
- **Warning**: 세션 만료, 스크린샷 차단
- **Info**: 성공 이벤트, 일반 작업

```dart
enum AuditEventType {
  // Authentication (인증)
  authBiometricSuccess,
  authBiometricFailed,
  authPinSuccess,
  authPinFailed,
  authSessionExpired,

  // Encryption (암호화)
  encryptionSuccess,
  encryptionFailed,
  decryptionSuccess,
  decryptionFailed,
  keyDerivationSuccess,
  keyDerivationFailed,

  // Wallet (지갑)
  walletCreated,
  walletImported,
  walletDeleted,
  walletExported,
  mnemonicAccessed,
  privateKeyAccessed,

  // Transaction (트랜잭션)
  transactionSigned,
  transactionSent,
  transactionFailed,

  // Security (보안)
  deviceIntegrityCheckPassed,
  deviceIntegrityCheckFailed,
  screenshotAttemptBlocked,
  suspiciousActivityDetected,

  // Settings (설정)
  biometricEnabled,
  biometricDisabled,
  pinChanged,
  securitySettingsChanged,
}
```

### 2. AuditLogEntry

감사 로그 엔트리 엔티티.

**속성:**
- `id`: UUID v4 고유 식별자
- `timestamp`: 이벤트 발생 시각 (ISO 8601)
- `eventType`: 이벤트 유형
- `metadata`: 추가 정보 (Map<String, dynamic>)
- `errorMessage`: 오류 메시지 (실패 시)
- `stackTrace`: 스택 트레이스 (오류 시)
- `isEncrypted`: 민감 정보 암호화 여부

**Computed 속성:**
- `severity`: eventType으로부터 자동 계산
- `category`: eventType으로부터 자동 계산

### 3. SecurityAuditLogger

핵심 감사 로깅 서비스.

**주요 메서드:**

```dart
// 이벤트 로그 기록
await logger.log(
  AuditEventType.authBiometricSuccess,
  metadata: {'deviceId': 'abc123'},
);

// 오류 로그 기록
await logger.logError(
  AuditEventType.decryptionFailed,
  error,
  stackTrace: stackTrace,
);

// 로그 조회
final logs = await logger.getLogs(
  eventType: AuditEventType.authPinFailed,
  from: DateTime.now().subtract(Duration(days: 7)),
  to: DateTime.now(),
  limit: 50,
);

// Critical 이벤트 조회
final criticalLogs = await logger.getCriticalEvents(
  from: DateTime.now().subtract(Duration(days: 1)),
);

// 통계 조회
final stats = await logger.getStatistics();

// 오래된 로그 정리
final deletedCount = await logger.purgeOldLogs();

// 로그 내보내기 (암호화)
final exportedData = await logger.exportLogs(
  from: DateTime.now().subtract(Duration(days: 30)),
  pin: userPin,
);

// 모든 로그 삭제
await logger.clearAllLogs();
```

### 4. AuditLogStatistics

로그 통계 정보.

**제공 데이터:**
- 전체 로그 수
- 심각도별 카운트 (critical, warning, info)
- 카테고리별 카운트
- 이벤트 유형별 카운트
- 로그 시간 범위 (oldest ~ newest)
- 최근 Critical 이벤트 목록 (최대 10개)

**Computed 속성:**
- `criticalPercentage`: Critical 이벤트 비율
- `warningPercentage`: Warning 이벤트 비율
- `infoPercentage`: Info 이벤트 비율
- `topEventTypes`: 가장 빈번한 이벤트 상위 5개
- `retentionDays`: 로그 보관 일수

## 보안 특성

### Defense-in-Depth 보안

```
┌───────────────────────────────────────────┐
│ Layer 3: 민감 정보 암호화                 │
│ - privateKey, mnemonic 등 자동 탐지       │
│ - 메타데이터 선택적 암호화                │
├───────────────────────────────────────────┤
│ Layer 2: 전체 로그 암호화                 │
│ - AES-256-GCM 암호화                      │
│ - SecureStorage (Platform 암호화)         │
├───────────────────────────────────────────┤
│ Layer 1: 접근 제어                        │
│ - PIN 기반 로그 내보내기                  │
│ - 플랫폼 보안 저장소 (Keychain/Keystore)  │
└───────────────────────────────────────────┘
```

### 암호화 아키텍처

**민감 정보 자동 탐지:**
```dart
const sensitiveKeys = [
  'privateKey',
  'mnemonic',
  'pin',
  'password',
  'seed',
  'secret',
];
```

메타데이터에 위 키가 포함되면 자동으로 `isEncrypted = true` 설정.

**로그 저장 형식:**
```
SecureStorage (Platform 암호화)
└─> JSON Array (모든 로그)
    └─> Individual Logs (민감 정보는 암호화 표시)
```

**로그 내보내기 형식:**
```json
{
  "version": "1.0",
  "salt": "base64-encoded-salt",
  "data": "aes-256-gcm-encrypted-logs",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## 로그 관리

### 자동 정리 메커니즘

1. **최대 로그 수 제한:**
   - 기본값: 1000개
   - 초과 시 가장 오래된 것부터 삭제
   - 로그 기록 시마다 자동 실행

2. **보관 기간:**
   - 기본값: 30일
   - `purgeOldLogs()` 수동 호출 필요
   - 백그라운드 작업으로 스케줄링 권장

### 로그 인덱싱

빠른 조회를 위한 인덱스 저장:

```dart
StorageKeys.auditLogIndex  // 로그 총 개수
```

## 사용 예시

### 1. 기본 사용법

```dart
// Provider 주입
final logger = ref.watch(securityAuditLoggerProvider);

// 성공 이벤트 로그
await logger.log(
  AuditEventType.authBiometricSuccess,
  metadata: {
    'deviceId': deviceInfo.id,
    'biometricType': 'faceId',
  },
);

// 실패 이벤트 로그
try {
  await decryptData();
} catch (e, stackTrace) {
  await logger.logError(
    AuditEventType.decryptionFailed,
    e,
    stackTrace: stackTrace,
    metadata: {'dataType': 'mnemonic'},
  );
}
```

### 2. 통계 대시보드

```dart
class SecurityDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(auditStatisticsProvider);

    return statsAsync.when(
      data: (stats) => Column(
        children: [
          Text('Total Logs: ${stats.totalLogs}'),
          Text('Critical: ${stats.criticalCount}'),
          Text('Warning: ${stats.warningCount}'),
          Text('Info: ${stats.infoCount}'),

          // 카테고리별 차트
          PieChart(stats.byCategory),

          // 최근 Critical 이벤트
          ListView.builder(
            itemCount: stats.recentCriticalEvents.length,
            itemBuilder: (context, index) {
              final event = stats.recentCriticalEvents[index];
              return ListTile(
                title: Text(event.eventType.displayName),
                subtitle: Text(event.timestamp.toString()),
              );
            },
          ),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 3. 로그 내보내기

```dart
// 사용자 PIN 입력 받기
final pin = await showPinDialog();

// 지난 30일 로그 내보내기
final exportedData = await logger.exportLogs(
  from: DateTime.now().subtract(Duration(days: 30)),
  pin: pin,
);

// 파일로 저장 또는 공유
await shareExportedLogs(exportedData);
```

## 통합 가이드

### 1. 기존 서비스에 로깅 추가

**BiometricKeyService 예시:**

```dart
class BiometricKeyService {
  BiometricKeyService({
    required this.auditLogger,  // 추가
    // ... 기존 의존성
  });

  final SecurityAuditLogger auditLogger;

  Future<String> getOrCreateKey() async {
    try {
      final key = await _getKey();

      // 성공 로그
      await auditLogger.log(
        AuditEventType.authBiometricSuccess,
      );

      return key;
    } catch (e, stackTrace) {
      // 실패 로그
      await auditLogger.logError(
        AuditEventType.authBiometricFailed,
        e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
```

### 2. WalletRepository 통합

```dart
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required this.auditLogger,
    // ... 기존 의존성
  });

  final SecurityAuditLogger auditLogger;

  @override
  Future<Wallet> createWallet(String pin) async {
    final wallet = await _createWalletInternal(pin);

    await auditLogger.log(
      AuditEventType.walletCreated,
      metadata: {
        'walletAddress': wallet.address,
      },
    );

    return wallet;
  }

  @override
  Future<String> getMnemonic(String pin) async {
    final mnemonic = await _getMnemonicInternal(pin);

    // Critical 이벤트 - 민감 정보 접근
    await auditLogger.log(
      AuditEventType.mnemonicAccessed,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return mnemonic;
  }
}
```

### 3. TransactionService 통합

```dart
class TransactionService {
  Future<String> sendTransaction(Transaction tx) async {
    try {
      final hash = await _sendTransactionInternal(tx);

      await auditLogger.log(
        AuditEventType.transactionSent,
        metadata: {
          'txHash': hash,
          'to': tx.to,
          'amount': tx.amount.toString(),
          'network': tx.network,
        },
      );

      return hash;
    } catch (e, stackTrace) {
      await auditLogger.logError(
        AuditEventType.transactionFailed,
        e,
        stackTrace: stackTrace,
        metadata: {
          'to': tx.to,
          'amount': tx.amount.toString(),
        },
      );
      rethrow;
    }
  }
}
```

## 성능 고려사항

### 1. 비동기 로깅

로그 기록은 비동기로 처리하되, 중요 작업 흐름을 차단하지 않도록 주의:

```dart
// ✅ 좋은 예: await로 로그 완료 보장
await logger.log(AuditEventType.walletCreated);

// ⚠️ 주의: Fire-and-forget (로그 실패 무시)
logger.log(AuditEventType.authBiometricSuccess);
```

### 2. 메모리 관리

- 로그는 JSON 배열로 메모리에 로드됨
- 최대 로그 수를 적절히 설정 (기본 1000개)
- 대량 조회 시 `limit` 파라미터 사용

### 3. 디스크 사용량

예상 로그 크기:
- 평균 엔트리: ~500 bytes
- 1000개 로그: ~500 KB
- 압축 없음 (SecureStorage는 플랫폼에서 처리)

## 테스트

### 단위 테스트

```bash
# 전체 테스트
flutter test test/core/security/

# 개별 테스트
flutter test test/core/security/audit_event_type_test.dart
flutter test test/core/security/audit_log_entry_test.dart
flutter test test/core/security/security_audit_logger_test.dart
```

### 테스트 커버리지

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

목표: 80% 이상

## 향후 개선 사항

### 1. 원격 로그 동기화

```dart
class RemoteAuditSync {
  Future<void> syncLogs() async {
    final logs = await logger.getLogs();
    await apiClient.uploadLogs(logs);
  }
}
```

### 2. 로그 압축

```dart
class CompressedAuditLogger extends SecurityAuditLogger {
  Future<void> _saveAllLogs(List<AuditLogEntry> logs) async {
    final json = jsonEncode(logs);
    final compressed = gzip.encode(utf8.encode(json));
    // ...
  }
}
```

### 3. 실시간 알림

```dart
class AuditAlertService {
  void startMonitoring() {
    logger.logStream.listen((entry) {
      if (entry.requiresAlert) {
        _showNotification(entry);
      }
    });
  }
}
```

### 4. ML 기반 이상 탐지

```dart
class AnomalyDetector {
  Future<bool> detectAnomaly(AuditLogEntry entry) async {
    final stats = await logger.getStatistics();
    // ML 모델로 패턴 분석
    return _mlModel.predict(entry, stats);
  }
}
```

## 참고 자료

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [NIST SP 800-92: Guide to Computer Security Log Management](https://csrc.nist.gov/publications/detail/sp/800-92/final)
- [CIS Critical Security Controls v8](https://www.cisecurity.org/controls/v8)

## 라이선스

MIT License - 프로젝트 루트의 LICENSE 파일 참조
