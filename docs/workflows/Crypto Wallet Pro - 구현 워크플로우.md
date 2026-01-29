# Crypto Wallet Pro - 구현 워크플로우

## 📋 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Crypto Wallet Pro (EtherFlow) |
| 기간 | 2025.12.01 ~ 2025.12.31 (4주) |
| 플랫폼 | Flutter (Android/iOS) |
| 아키텍처 | Clean Architecture + Riverpod 2.0 |

---

## 🗂️ Phase 0: 프로젝트 초기 설정 (Day 1-2)

### 0.1 프로젝트 생성 및 폴더 구조

```bash
flutter create --org com.etherflow crypto_wallet_pro
```

### 0.2 Clean Architecture 폴더 구조

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── network_constants.dart
│   │   └── storage_keys.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── network_info.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── glassmorphism.dart
│   ├── utils/
│   │   ├── input_validators.dart
│   │   └── formatters.dart
│   └── widgets/
│       ├── loading_indicator.dart
│       └── custom_button.dart
│
├── features/
│   ├── wallet/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── wallet_local_datasource.dart
│   │   │   │   └── wallet_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── wallet_model.dart
│   │   │   └── repositories/
│   │   │       └── wallet_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── wallet.dart
│   │   │   ├── repositories/
│   │   │   │   └── wallet_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_wallet.dart
│   │   │       ├── import_wallet.dart
│   │   │       └── get_wallet.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── wallet_provider.dart
│   │       ├── pages/
│   │       │   ├── create_wallet_page.dart
│   │       │   └── import_wallet_page.dart
│   │       └── widgets/
│   │           └── mnemonic_grid.dart
│   │
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── send/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── wallet_connect/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── nft/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/
    ├── providers/
    │   └── network_provider.dart
    └── services/
        ├── secure_storage_service.dart
        └── biometric_service.dart
```

### 0.3 핵심 의존성 설치

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Blockchain
  web3dart: ^2.7.3
  bip39: ^1.0.6
  bip32: ^2.0.0
  walletconnect_flutter_v2: ^2.2.0
  
  # Storage
  flutter_secure_storage: ^9.0.0
  hive_flutter: ^1.1.0
  
  # Network
  dio: ^5.4.0
  
  # UI/UX
  lottie: ^2.7.0
  cached_network_image: ^3.3.0
  qr_code_scanner: ^1.0.1
  qr_flutter: ^4.1.0
  
  # Utils
  fpdart: ^1.1.0
  equatable: ^2.0.5
  intl: ^0.18.1
  local_auth: ^2.1.8
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.8
  freezed: ^2.4.6
  freezed_annotation: ^2.4.1
  json_serializable: ^6.7.1
```

### 0.4 환경 설정 파일

```dart
// lib/core/constants/env_config.dart
enum NetworkType { mainnet, sepolia }

class EnvConfig {
  static const String alchemyApiKey = 'YOUR_ALCHEMY_API_KEY';
  
  static String getRpcUrl(NetworkType network) {
    switch (network) {
      case NetworkType.mainnet:
        return 'https://eth-mainnet.g.alchemy.com/v2/$alchemyApiKey';
      case NetworkType.sepolia:
        return 'https://eth-sepolia.g.alchemy.com/v2/$alchemyApiKey';
    }
  }
}
```

---

## 🔐 Phase 1: Core Wallet (Week 1)

### Day 1-2: 니모닉 및 키 파생 로직

#### Task 1.1: Mnemonic 생성 유틸리티

```dart
// lib/features/wallet/data/datasources/wallet_local_datasource.dart

abstract class WalletLocalDataSource {
  Future<String> generateMnemonic();
  Future<EthPrivateKey> derivePrivateKey(String mnemonic);
  Future<void> saveMnemonic(String mnemonic);
  Future<String?> getMnemonic();
  Future<void> deleteMnemonic();
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  
  @override
  Future<String> generateMnemonic() async {
    return bip39.generateMnemonic(strength: 128); // 12 words
  }
  
  @override
  Future<EthPrivateKey> derivePrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final node = bip32.BIP32.fromSeed(seed);
    // m/44'/60'/0'/0/0 - Ethereum derivation path
    final child = node.derivePath("m/44'/60'/0'/0/0");
    return EthPrivateKey.fromHex(HEX.encode(child.privateKey!));
  }
}
```

#### Task 1.2: Wallet Entity & Model

```dart
// lib/features/wallet/domain/entities/wallet.dart
class Wallet extends Equatable {
  final String address;
  final String? ensName;
  final BigInt balance;
  
  const Wallet({
    required this.address,
    this.ensName,
    this.balance = BigInt.zero,
  });
  
  @override
  List<Object?> get props => [address, ensName, balance];
}
```

#### Task 1.3: Repository Pattern 구현

```dart
// lib/features/wallet/domain/repositories/wallet_repository.dart
abstract class WalletRepository {
  Future<Either<Failure, Wallet>> createWallet();
  Future<Either<Failure, Wallet>> importWallet(String mnemonic);
  Future<Either<Failure, Wallet>> getStoredWallet();
  Future<Either<Failure, void>> deleteWallet();
}
```

### Day 3-4: UseCase 및 Provider 구현

#### Task 1.4: CreateWallet UseCase

```dart
// lib/features/wallet/domain/usecases/create_wallet.dart
class CreateWallet {
  final WalletRepository repository;
  
  CreateWallet(this.repository);
  
  Future<Either<Failure, Wallet>> call() async {
    return await repository.createWallet();
  }
}
```

#### Task 1.5: Riverpod Provider (Code Generation)

```dart
// lib/features/wallet/presentation/providers/wallet_provider.dart
part 'wallet_provider.g.dart';

@riverpod
class WalletNotifier extends _$WalletNotifier {
  @override
  FutureOr<Wallet?> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    final result = await repository.getStoredWallet();
    return result.fold(
      (failure) => null,
      (wallet) => wallet,
    );
  }
  
  Future<void> createWallet() async {
    state = const AsyncLoading();
    final repository = ref.read(walletRepositoryProvider);
    final result = await repository.createWallet();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (wallet) => AsyncData(wallet),
    );
  }
  
  Future<void> importWallet(String mnemonic) async {
    state = const AsyncLoading();
    final repository = ref.read(walletRepositoryProvider);
    final result = await repository.importWallet(mnemonic);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (wallet) => AsyncData(wallet),
    );
  }
}
```

### Day 5-6: UI 구현 및 보안

#### Task 1.6: 지갑 생성 화면

```dart
// lib/features/wallet/presentation/pages/create_wallet_page.dart
class CreateWalletPage extends ConsumerStatefulWidget {
  // 니모닉 표시 그리드
  // 백업 확인 체크박스
  // 지갑 생성 버튼
}
```

#### Task 1.7: 생체 인증 서비스

```dart
// lib/shared/services/biometric_service.dart
class BiometricService {
  final LocalAuthentication _localAuth;
  
  Future<bool> authenticate() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;
    
    return await _localAuth.authenticate(
      localizedReason: 'Authenticate to access your wallet',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}
```

### Day 7: Week 1 마무리 및 테스트

#### Checklist Week 1:
- [ ] 니모닉 12단어 생성 확인
- [ ] 동일 니모닉 → 동일 주소 파생 검증
- [ ] Secure Storage 저장/불러오기 확인
- [ ] 앱 재시작 후 지갑 유지 확인
- [ ] 생체 인증 또는 PIN 잠금 동작 확인

---

## ⛓️ Phase 2: Blockchain Interaction (Week 2)

### Day 8-9: Web3 Client 설정

#### Task 2.1: Ethereum RPC Client

```dart
// lib/core/network/web3_client.dart
@riverpod
Web3Client web3Client(Web3ClientRef ref) {
  final network = ref.watch(selectedNetworkProvider);
  final rpcUrl = EnvConfig.getRpcUrl(network);
  return Web3Client(rpcUrl, Client());
}
```

#### Task 2.2: Balance Remote DataSource

```dart
// lib/features/dashboard/data/datasources/balance_remote_datasource.dart
class BalanceRemoteDataSourceImpl implements BalanceRemoteDataSource {
  final Web3Client _web3Client;
  
  @override
  Future<BigInt> getEthBalance(String address) async {
    final ethAddress = EthereumAddress.fromHex(address);
    final balance = await _web3Client.getBalance(ethAddress);
    return balance.getInWei;
  }
  
  @override
  Future<BigInt> getERC20Balance(String tokenAddress, String walletAddress) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(erc20Abi, 'ERC20'),
      EthereumAddress.fromHex(tokenAddress),
    );
    final balanceFunction = contract.function('balanceOf');
    final result = await _web3Client.call(
      contract: contract,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(walletAddress)],
    );
    return result.first as BigInt;
  }
}
```

### Day 10-11: 잔액 조회 및 토큰 리스트

#### Task 2.3: Dashboard Provider (StreamProvider 활용)

```dart
// lib/features/dashboard/presentation/providers/balance_provider.dart
@riverpod
Stream<BigInt> ethBalanceStream(EthBalanceStreamRef ref) async* {
  final wallet = ref.watch(walletNotifierProvider).valueOrNull;
  if (wallet == null) return;
  
  final repository = ref.watch(balanceRepositoryProvider);
  
  while (true) {
    final result = await repository.getEthBalance(wallet.address);
    yield* result.fold(
      (failure) => Stream.error(failure),
      (balance) => Stream.value(balance),
    );
    await Future.delayed(const Duration(seconds: 15)); // Poll every 15s
  }
}
```

#### Task 2.4: Token List 조회 (Alchemy API)

```dart
// Alchemy Token Balances API 연동
// GET https://eth-mainnet.g.alchemy.com/v2/{apiKey}/getTokenBalances
```

### Day 12-13: 송금 기능 구현

#### Task 2.5: Transaction UseCase

```dart
// lib/features/send/domain/usecases/send_transaction.dart
class SendTransaction {
  final TransactionRepository repository;
  
  Future<Either<Failure, String>> call(SendTransactionParams params) async {
    // 1. Validate address
    // 2. Estimate gas (EIP-1559)
    // 3. Sign transaction
    // 4. Broadcast
    return repository.sendTransaction(params);
  }
}

class SendTransactionParams {
  final String toAddress;
  final BigInt amount;
  final GasPriority priority; // low, medium, high
}
```

#### Task 2.6: Gas Estimation (EIP-1559)

```dart
// lib/features/send/data/datasources/transaction_remote_datasource.dart
Future<GasEstimate> estimateGas({
  required String from,
  required String to,
  required BigInt value,
}) async {
  final gasPrice = await _web3Client.getGasPrice();
  final maxPriorityFee = await _getMaxPriorityFeePerGas();
  final baseFee = await _getBaseFee();
  
  return GasEstimate(
    low: _calculateFee(baseFee, maxPriorityFee, 0.9),
    medium: _calculateFee(baseFee, maxPriorityFee, 1.0),
    high: _calculateFee(baseFee, maxPriorityFee, 1.2),
  );
}
```

### Day 14: Week 2 마무리

#### Checklist Week 2:
- [ ] ETH 잔액 실시간 조회 확인
- [ ] ERC-20 토큰 잔액 표시 확인
- [ ] Sepolia 테스트넷 송금 성공
- [ ] Gas Fee 옵션 (Low/Medium/High) 동작 확인
- [ ] 트랜잭션 해시 반환 및 표시

---

## 🔗 Phase 3: Advanced Features (Week 3)

### Day 15-17: WalletConnect v2 연동

#### Task 3.1: WalletConnect 초기화

```dart
// lib/features/wallet_connect/data/services/wallet_connect_service.dart
class WalletConnectService {
  late Web3Wallet _web3Wallet;
  
  Future<void> initialize() async {
    _web3Wallet = await Web3Wallet.createInstance(
      projectId: 'YOUR_PROJECT_ID', // cloud.walletconnect.com에서 발급
      metadata: const PairingMetadata(
        name: 'Crypto Wallet Pro',
        description: 'A secure Ethereum wallet',
        url: 'https://etherflow.app',
        icons: ['https://etherflow.app/icon.png'],
      ),
    );
    
    // Session Request Handler 등록
    _web3Wallet.onSessionProposal.subscribe(_onSessionProposal);
    _web3Wallet.onSessionRequest.subscribe(_onSessionRequest);
  }
  
  Future<void> pair(String uri) async {
    await _web3Wallet.pair(uri: Uri.parse(uri));
  }
}
```

#### Task 3.2: Session 관리 Provider

```dart
// lib/features/wallet_connect/presentation/providers/wc_session_provider.dart
@riverpod
class WcSessionNotifier extends _$WcSessionNotifier {
  @override
  List<SessionData> build() => [];
  
  Future<void> approveSession(SessionProposalEvent proposal) async {
    // 세션 승인 로직
  }
  
  Future<void> handleSignRequest(SessionRequestEvent request) async {
    // eth_sendTransaction, personal_sign 등 처리
  }
}
```

#### Task 3.3: QR 스캐너 및 연결 UI

```dart
// lib/features/wallet_connect/presentation/pages/qr_scanner_page.dart
// QR 코드 스캔 → URI 추출 → pair() 호출
```

### Day 18-19: ENS 리졸버 구현

#### Task 3.4: ENS Resolution

```dart
// lib/features/dashboard/data/datasources/ens_datasource.dart
class EnsDataSourceImpl implements EnsDataSource {
  final Web3Client _web3Client;
  
  // Forward Resolution: name -> address
  Future<String?> resolveAddress(String ensName) async {
    // ENS Registry 컨트랙트 호출
    // Resolver 주소 조회 → addr(node) 호출
  }
  
  // Reverse Resolution: address -> name
  Future<String?> reverseLookup(String address) async {
    // {address}.addr.reverse 조회
  }
}
```

#### Task 3.5: 주소 입력 시 ENS 자동 변환

```dart
// 송금 화면에서 'vitalik.eth' 입력 시
// 자동으로 0x... 주소 표시
```

### Day 20-21: Week 3 마무리 및 통합 테스트

#### Checklist Week 3:
- [ ] WalletConnect QR 스캔 → 세션 연결 성공
- [ ] dApp에서 트랜잭션 요청 → 앱에서 승인 팝업
- [ ] 승인 후 트랜잭션 전송 성공
- [ ] ENS 이름 → 주소 변환 확인
- [ ] 주소 → ENS 이름 역방향 조회 확인

---

## 🎨 Phase 4: NFT & Polish (Week 4)

### Day 22-23: NFT 갤러리

#### Task 4.1: NFT Remote DataSource (Alchemy NFT API)

```dart
// lib/features/nft/data/datasources/nft_remote_datasource.dart
class NftRemoteDataSourceImpl implements NftRemoteDataSource {
  final Dio _dio;
  
  @override
  Future<List<NftModel>> getNftsForOwner(String address) async {
    final response = await _dio.get(
      'https://eth-mainnet.g.alchemy.com/nft/v3/$apiKey/getNFTsForOwner',
      queryParameters: {'owner': address, 'withMetadata': true},
    );
    // Parse response
  }
}
```

#### Task 4.2: NFT Grid UI

```dart
// lib/features/nft/presentation/pages/nft_gallery_page.dart
// cached_network_image를 활용한 이미지 캐싱
// GridView.builder로 스크롤 최적화
```

### Day 24-25: UI/UX 고도화

#### Task 4.3: Glassmorphism 테마

```dart
// lib/core/theme/glassmorphism.dart
class GlassMorphism extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

#### Task 4.4: Lottie 애니메이션

```dart
// 송금 성공 시 애니메이션
Lottie.asset('assets/animations/success.json')
```

#### Task 4.5: 숫자 카운팅 애니메이션

```dart
// lib/core/widgets/animated_counter.dart
class AnimatedCounter extends StatelessWidget {
  final BigInt value;
  // TweenAnimationBuilder를 활용한 숫자 애니메이션
}
```

### Day 26-27: 코드 정리 및 리팩토링

#### Task 4.6: 코드 품질 체크리스트

- [ ] 모든 Provider에 에러 핸들링 적용
- [ ] 사용되지 않는 import 제거
- [ ] 주석 및 문서화
- [ ] 로그에 민감 정보 출력 없음 확인

### Day 28: README 및 문서화

#### Task 4.7: README.md 작성

```markdown
# Crypto Wallet Pro

## Architecture
[다이어그램 삽입]

## Features
- ✅ Create/Import Wallet
- ✅ ETH & ERC-20 Balance
- ✅ Send Transaction (EIP-1559)
- ✅ WalletConnect v2
- ✅ ENS Support
- ✅ NFT Gallery

## Tech Stack
- Flutter + Riverpod 2.0
- Clean Architecture
- web3dart, WalletConnect

## Getting Started
...
```

---

## 📊 일일 진행 체크리스트

| Week | Day | Task | Status |
|------|-----|------|--------|
| 1 | 1-2 | 프로젝트 설정 & 폴더 구조 | ⬜ |
| 1 | 3-4 | 니모닉 생성 & 키 파생 | ⬜ |
| 1 | 5-6 | Secure Storage & 지갑 UI | ⬜ |
| 1 | 7 | 생체 인증 & Week 1 테스트 | ⬜ |
| 2 | 8-9 | Web3 Client & RPC 연동 | ⬜ |
| 2 | 10-11 | 잔액 조회 (ETH, ERC-20) | ⬜ |
| 2 | 12-13 | 송금 기능 (Gas Estimation) | ⬜ |
| 2 | 14 | Sepolia 테스트 & Week 2 마무리 | ⬜ |
| 3 | 15-17 | WalletConnect v2 연동 | ⬜ |
| 3 | 18-19 | ENS 리졸버 구현 | ⬜ |
| 3 | 20-21 | 통합 테스트 & Week 3 마무리 | ⬜ |
| 4 | 22-23 | NFT 갤러리 구현 | ⬜ |
| 4 | 24-25 | UI/UX 고도화 | ⬜ |
| 4 | 26-27 | 코드 리팩토링 | ⬜ |
| 4 | 28 | README & 포트폴리오 정리 | ⬜ |

---

## 🎯 면접 대비 핵심 포인트

### 1. 상태 관리 관련 예상 질문

> "비동기 블록체인 데이터와 로컬 지갑 데이터의 싱크를 어떻게 처리했나요?"

**답변 포인트:**
- `AsyncNotifier`로 로딩/성공/에러 상태 자동 관리
- `StreamProvider`로 잔액 폴링 구현
- `ref.invalidate()`로 수동 새로고침

### 2. 아키텍처 관련 예상 질문

> "web3dart 라이브러리가 변경되면 어디를 수정해야 하나요?"

**답변 포인트:**
- Data Layer의 DataSource만 수정
- Domain Layer (UseCase, Entity)는 영향 없음
- Repository 인터페이스가 추상화 담당

### 3. 보안 관련 예상 질문

> "Private Key는 어떻게 관리하나요?"

**답변 포인트:**
- `flutter_secure_storage`로 암호화 저장
- 키 접근 시 생체 인증 필수
- 로그/서버 전송 절대 금지

### 4. UX 관련 예상 질문

> "블록체인의 느린 응답 속도는 어떻게 처리했나요?"

**답변 포인트:**
- 로딩 인디케이터 표시
- Optimistic UI (송금 후 즉시 잔액 감소 표시)
- 트랜잭션 상태 실시간 업데이트

---

## 🔧 개발 환경 설정

### API 키 발급 체크리스트

- [ ] **Alchemy**: https://dashboard.alchemy.com
  - Ethereum Mainnet API Key
  - Sepolia Testnet API Key
  
- [ ] **WalletConnect**: https://cloud.walletconnect.com
  - Project ID 발급

- [ ] **Sepolia Faucet**: 테스트 ETH 수령
  - https://sepoliafaucet.com

---

## 📁 Git 브랜치 전략

```
main
├── develop
│   ├── feature/wallet-core
│   ├── feature/blockchain-interaction
│   ├── feature/wallet-connect
│   ├── feature/ens-support
│   └── feature/nft-gallery
└── release/v1.0.0
```

---

*마지막 업데이트: 2025.12.01*