# Phase 8: 원격 보안 동기화 (Remote Security Sync)

## 개요

Phase 8은 E2E 암호화 기반의 원격 보안 동기화 시스템을 구현합니다. 감사 로그, 보안 설정 등을 멀티 디바이스 간 안전하게 동기화할 수 있습니다.

## 목차

- [아키텍처](#아키텍처)
- [보안 프로토콜](#보안-프로토콜)
- [동기화 흐름](#동기화-흐름)
- [충돌 해결](#충돌-해결)
- [API 레퍼런스](#api-레퍼런스)
- [사용 예시](#사용-예시)

---

## 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────────────────────┐
│ Client Layer (Flutter App)                              │
├─────────────────────────────────────────────────────────┤
│ ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  │
│ │ Audit Logger  │→│ Sync Service │→│ Sync Protocol│  │
│ └───────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                 │          │
│         └──────────────────┴─────────────────┘          │
│                            │                            │
│                    E2E Encryption                       │
│                   (AES-256-GCM)                         │
└─────────────────────────────────────────────────────────┘
                            │
                       TLS 1.3
                            │
                            ↓
┌─────────────────────────────────────────────────────────┐
│ Server Layer (Zero-Knowledge)                           │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│ │ API Gateway │→│ Sync Storage │→│ Device Registry │ │
│ └─────────────┘  └──────────────┘  └─────────────────┘ │
│                                                          │
│ - Encrypted Blobs Only                                  │
│ - No Decryption Keys                                    │
│ - Metadata Indexing                                     │
└─────────────────────────────────────────────────────────┘
```

### 디렉토리 구조

```
lib/core/security/
├── sync/
│   ├── sync_payload.dart          # 암호화된 데이터 전송 단위
│   ├── sync_result.dart           # 동기화 결과 및 충돌
│   ├── sync_config.dart           # 동기화 설정
│   ├── secure_sync_protocol.dart  # E2E 암호화 프로토콜
│   └── sync_conflict_resolver.dart # 충돌 해결기
├── services/
│   └── remote_security_sync_service.dart # 원격 동기화 서비스
└── providers/
    └── sync_providers.dart        # Riverpod 프로바이더
```

---

## 보안 프로토콜

### E2E 암호화 체계

```
┌─────────────────────────────────────────────────────────┐
│ 1. 키 파생 (Key Derivation)                             │
├─────────────────────────────────────────────────────────┤
│ Master Key (PIN/Biometric)                              │
│     │                                                    │
│     ├─> PBKDF2-SHA512 (100,000 iterations)              │
│     │   - Salt: Sync-specific salt                      │
│     │   - Context: "SYNC_KEY_V1"                        │
│     │                                                    │
│     └─> Sync Key (AES-256, 32 bytes)                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 2. 데이터 암호화 (Data Encryption)                       │
├─────────────────────────────────────────────────────────┤
│ Plaintext Data                                          │
│     │                                                    │
│     ├─> AES-256-GCM Encryption                          │
│     │   - Random IV (12 bytes)                          │
│     │   - Auth Tag (16 bytes)                           │
│     │   - AEAD (Authenticated Encryption)               │
│     │                                                    │
│     └─> Encrypted Payload                               │
│         ├─> IV (Base64)                                 │
│         ├─> Ciphertext (Base64)                         │
│         ├─> Auth Tag (Base64)                           │
│         └─> Checksum (SHA-256)                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 3. 전송 보안 (Transport Security)                        │
├─────────────────────────────────────────────────────────┤
│ Encrypted Payload                                       │
│     │                                                    │
│     ├─> HTTPS (TLS 1.3)                                 │
│     │   - Certificate Pinning (권장)                    │
│     │   - Perfect Forward Secrecy                       │
│     │                                                    │
│     └─> Server (Zero-Knowledge Storage)                 │
└─────────────────────────────────────────────────────────┘
```

### Zero-Knowledge 원칙

서버는 다음 정보만 알 수 있습니다:

- **메타데이터**: 페이로드 ID, 타임스탬프, 디바이스 ID, 데이터 유형
- **암호화된 Blob**: 복호화 불가능한 암호문

서버는 다음을 알 수 없습니다:

- 원본 데이터 내용
- 암호화 키
- 사용자의 PIN 또는 생체인증 정보

---

## 동기화 흐름

### 전체 동기화 프로세스

```
┌──────────────────────────────────────────────────────────┐
│ Step 1: Prepare Local Data                               │
├──────────────────────────────────────────────────────────┤
│ • Collect changed audit logs                             │
│ • Collect security settings                              │
│ • Check last sync timestamp                              │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ Step 2: Encrypt & Sign                                   │
├──────────────────────────────────────────────────────────┤
│ • Derive sync key from master key                        │
│ • Encrypt data with AES-256-GCM                          │
│ • Generate checksum (SHA-256)                            │
│ • Create SyncPayload                                     │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ Step 3: Upload to Server                                 │
├──────────────────────────────────────────────────────────┤
│ • POST /sync/upload                                      │
│ • TLS 1.3 transport                                      │
│ • Retry on failure (max 3 times)                         │
│ • Queue offline if no network                            │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ Step 4: Download Remote Changes                          │
├──────────────────────────────────────────────────────────┤
│ • GET /sync/download?since=<last_sync_time>              │
│ • Receive encrypted payloads                             │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ Step 5: Resolve Conflicts                                │
├──────────────────────────────────────────────────────────┤
│ • Compare timestamps                                     │
│ • Apply conflict strategy:                               │
│   - Last Write Wins                                      │
│   - Local First                                          │
│   - Remote First                                         │
│   - Manual Resolution                                    │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ Step 6: Apply Changes                                    │
├──────────────────────────────────────────────────────────┤
│ • Decrypt remote payloads                                │
│ • Verify checksums                                       │
│ • Update local storage                                   │
│ • Log sync event                                         │
└──────────────────────────────────────────────────────────┘
```

### 오프라인 큐잉

네트워크가 없을 때:

```dart
1. 변경사항을 로컬 큐에 저장
2. 네트워크 복구 시 자동 업로드
3. 큐 크기 제한 (기본 100개)
4. FIFO 방식으로 처리
```

---

## 충돌 해결

### 충돌 시나리오

```
Device A (Phone)          Device B (Tablet)
    │                         │
    ├─> Edit Settings         │
    │   v1 @ 10:00            │
    │                         ├─> Edit Settings
    │                         │   v1 @ 10:05
    │                         │
    ├─> Sync @ 10:10 ─────────┼─> CONFLICT!
    │                         │
    └─> Resolution ───────────┴─> Apply Strategy
```

### 충돌 해결 전략

#### 1. Last Write Wins (기본)

```dart
// 타임스탬프 비교
if (remoteTimestamp > localTimestamp) {
  applyRemoteChanges();
} else {
  keepLocalChanges();
}
```

**장점**: 자동 해결, 최신 데이터 유지
**단점**: 이전 변경사항 손실 가능

#### 2. Local First

```dart
// 항상 로컬 유지
keepLocalChanges();
```

**장점**: 로컬 변경사항 보호
**단점**: 원격 변경사항 손실

#### 3. Remote First

```dart
// 항상 원격 유지
applyRemoteChanges();
```

**장점**: 서버 우선 정책
**단점**: 로컬 변경사항 손실

#### 4. Manual Resolution

```dart
// 사용자 선택 대기
showConflictDialog(localData, remoteData);
await userDecision;
```

**장점**: 사용자 제어
**단점**: 사용자 개입 필요

---

## API 레퍼런스

### SyncPayload

```dart
class SyncPayload {
  final String id;              // UUID
  final SyncDataType dataType;  // auditLogs, securitySettings, etc.
  final String encryptedData;   // Base64 encrypted data
  final String iv;              // Base64 IV (12 bytes)
  final String authTag;         // Base64 AEAD tag (16 bytes)
  final int version;            // Data version
  final DateTime timestamp;     // Creation time (UTC)
  final String deviceId;        // Source device ID
  final String checksum;        // SHA-256 checksum
}
```

### SyncResult

```dart
class SyncResult {
  final SyncStatus status;      // success, failed, partialSuccess, etc.
  final int uploadedCount;      // Number of uploaded payloads
  final int downloadedCount;    // Number of downloaded payloads
  final int conflictCount;      // Number of conflicts
  final List<SyncConflict> conflicts;
  final DateTime? lastSyncTime;
  final String? errorMessage;
}
```

### RemoteSecuritySyncService

```dart
// 전체 동기화
await syncService.performSync(syncKey: syncKey);

// 감사 로그만 동기화
await syncService.syncAuditLogs(syncKey: syncKey);

// 보안 설정만 동기화
await syncService.syncSecuritySettings(syncKey: syncKey);

// 오프라인 큐 처리
await syncService.processOfflineQueue(syncKey: syncKey);

// 디바이스 등록
await syncService.registerDevice(
  deviceId: deviceId,
  deviceName: 'iPhone 15 Pro',
  publicKey: publicKey,
);

// 디바이스 목록 조회
final devices = await syncService.getRegisteredDevices();
```

---

## 사용 예시

### 1. 초기 설정

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncSetupPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(remoteSecuritySyncServiceProvider);
    final syncProtocol = ref.watch(secureSyncProtocolProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Sync Setup')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // 1. Sync Key 생성
              final masterKey = await getMasterKey();
              final salt = await getOrCreateSyncSalt();
              final syncKey = await syncProtocol.deriveSyncKey(
                masterKey: masterKey,
                salt: salt,
              );

              // 2. 디바이스 등록
              final deviceId = syncProtocol.generateDeviceId();
              await syncService.registerDevice(
                deviceId: deviceId,
                deviceName: await getDeviceName(),
                publicKey: await generatePublicKey(),
              );

              // 3. 저장
              await saveSyncKey(syncKey);
            },
            child: Text('Enable Sync'),
          ),
        ],
      ),
    );
  }
}
```

### 2. 자동 동기화

```dart
class SyncManager extends ConsumerStatefulWidget {
  @override
  _SyncManagerState createState() => _SyncManagerState();
}

class _SyncManagerState extends ConsumerState<SyncManager> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSync();
  }

  void _startAutoSync() {
    final config = ref.read(syncConfigProvider).value;
    if (config?.autoSyncEnabled != true) return;

    _syncTimer = Timer.periodic(config!.syncInterval, (_) async {
      final syncKey = await getSyncKey();
      if (syncKey != null) {
        await ref.read(syncStateProvider.notifier).performSync(
          syncKey: syncKey,
        );
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
```

### 3. 충돌 해결 UI

```dart
class ConflictResolutionDialog extends ConsumerWidget {
  final SyncConflict conflict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Sync Conflict Detected'),
      content: Column(
        children: [
          Text('Local: ${conflict.localTimestamp}'),
          Text('Remote: ${conflict.remoteTimestamp}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final resolver = ref.read(syncConflictResolverProvider);
            await resolver.resolveManualConflict(
              payloadId: conflict.payloadId,
              resolution: ConflictResolution.keepLocal,
            );
            Navigator.of(context).pop();
          },
          child: Text('Keep Local'),
        ),
        TextButton(
          onPressed: () async {
            final resolver = ref.read(syncConflictResolverProvider);
            await resolver.resolveManualConflict(
              payloadId: conflict.payloadId,
              resolution: ConflictResolution.keepRemote,
            );
            Navigator.of(context).pop();
          },
          child: Text('Keep Remote'),
        ),
      ],
    );
  }
}
```

### 4. 동기화 상태 표시

```dart
class SyncStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return Card(
      child: ListTile(
        leading: syncState.isSyncing
            ? CircularProgressIndicator()
            : Icon(
                syncState.lastResult?.isSuccess == true
                    ? Icons.cloud_done
                    : Icons.cloud_off,
              ),
        title: Text(
          syncState.isSyncing
              ? 'Syncing...'
              : 'Last sync: ${_formatTime(syncState.lastSyncTime)}',
        ),
        subtitle: syncState.error != null
            ? Text(syncState.error!, style: TextStyle(color: Colors.red))
            : null,
        trailing: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: syncState.isSyncing
              ? null
              : () async {
                  final syncKey = await getSyncKey();
                  if (syncKey != null) {
                    await ref.read(syncStateProvider.notifier).performSync(
                      syncKey: syncKey,
                    );
                  }
                },
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Never';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
```

---

## 보안 고려사항

### 1. 키 관리

- **Sync Key**: 마스터 키에서 파생, 안전한 저장소에 보관
- **Salt**: 디바이스별 고유 Salt 생성
- **키 순환**: 주기적으로 키 갱신 권장 (예: 90일)

### 2. 네트워크 보안

- **TLS 1.3**: 최신 전송 계층 보안
- **Certificate Pinning**: MITM 공격 방지
- **타임아웃**: 장시간 대기 방지 (기본 5분)

### 3. 데이터 보호

- **체크섬**: SHA-256으로 무결성 검증
- **AEAD**: 인증 암호화로 변조 방지
- **버저닝**: 충돌 해결 및 호환성 관리

### 4. 프라이버시

- **Zero-Knowledge**: 서버는 데이터 내용 모름
- **디바이스 격리**: 디바이스별 독립적인 암호화
- **로그 최소화**: 필요한 메타데이터만 서버 로깅

---

## 성능 최적화

### 1. 증분 동기화

현재는 전체 동기화만 지원하지만, 향후 개선 가능:

```dart
// 마지막 동기화 이후 변경사항만
GET /sync/download?since=2024-01-15T10:00:00Z
```

### 2. 압축

대량 데이터 전송 시 압축 고려:

```dart
// Gzip 압축 후 암호화
final compressed = gzip.encode(utf8.encode(data));
final encrypted = await encryptPayload(compressed);
```

### 3. 배치 처리

여러 페이로드를 한 번에 전송:

```dart
POST /sync/batch
{
  "payloads": [payload1, payload2, ...]
}
```

---

## 트러블슈팅

### 문제: 동기화 실패

**원인**:
- 네트워크 연결 없음
- 잘못된 Sync Key
- 서버 오류

**해결**:
```dart
// 1. 네트워크 확인
final connectivity = await checkConnectivity();

// 2. 오프라인 큐 확인
await syncService.processOfflineQueue(syncKey: syncKey);

// 3. 에러 로그 확인
final logs = await auditLogger.getCriticalEvents();
```

### 문제: 충돌 과다 발생

**원인**:
- 동기화 간격이 너무 김
- 여러 디바이스에서 동시 수정

**해결**:
```dart
// 동기화 간격 단축
final config = currentConfig.copyWith(
  syncInterval: Duration(minutes: 5),
);

// 충돌 전략 변경
final config = currentConfig.copyWith(
  defaultConflictStrategy: ConflictStrategy.lastWriteWins,
);
```

---

## 향후 개선 사항

1. **증분 동기화**: 변경사항만 전송
2. **P2P 동기화**: 서버 없이 디바이스 간 직접 동기화
3. **자동 병합**: 비충돌 필드 자동 병합
4. **암호화 알고리즘 업그레이드**: ChaCha20-Poly1305 지원
5. **압축**: Gzip/Brotli 지원
6. **배치 동기화**: 여러 페이로드 일괄 처리

---

## 참고 자료

- [AES-GCM Specification (NIST SP 800-38D)](https://csrc.nist.gov/publications/detail/sp/800-38d/final)
- [PBKDF2 Recommendation (NIST SP 800-132)](https://csrc.nist.gov/publications/detail/sp/800-132/final)
- [TLS 1.3 RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446)
- [Zero-Knowledge Encryption](https://en.wikipedia.org/wiki/Zero-knowledge_proof)

---

**구현 완료**: 2024-01-15
**마지막 업데이트**: 2024-01-15
**버전**: 1.0.0
