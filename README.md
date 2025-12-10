# Crypto Wallet Pro

A modern, feature-rich cryptocurrency wallet application built with Flutter.

Flutter로 개발된 현대적이고 기능이 풍부한 암호화폐 지갑 애플리케이션입니다.

## Features / 주요 기능

### Current Implementation (v1.4.0) / 현재 구현된 기능

- **Splash Screen**: Animated logo with glassmorphism effects
- **스플래시 화면**: 글래스모피즘 효과가 적용된 애니메이션 로고

- **Onboarding Flow**: 3-slide introduction showcasing key features
- **온보딩 플로우**: 주요 기능을 소개하는 3단계 슬라이드

- **Dashboard**: Main wallet interface with real-time balance display and token list
- **대시보드**: 실시간 잔액 표시 및 토큰 목록이 포함된 메인 지갑 인터페이스

- **Glassmorphism UI**: Modern dark theme with frosted glass effects
- **글래스모피즘 UI**: 프로스트 글래스 효과가 적용된 모던 다크 테마

- **Multi-Network Support**: Network selector for Mainnet/Testnet switching
- **멀티 네트워크 지원**: 메인넷/테스트넷 전환을 위한 네트워크 선택기

- **Pull-to-Refresh**: Refresh wallet data with swipe gesture
- **당겨서 새로고침**: 스와이프 제스처로 지갑 데이터 새로고침

- **Wallet Creation**: 4-step wizard with mnemonic generation and verification
- **지갑 생성**: 니모닉 생성 및 검증이 포함된 4단계 마법사

- **Wallet Import**: 12-word recovery phrase input with paste support
- **지갑 가져오기**: 붙여넣기 지원이 포함된 12단어 복구 문구 입력

- **NFT Gallery**: Grid view with ERC-721/ERC-1155 filtering and Hero animations
- **NFT 갤러리**: ERC-721/ERC-1155 필터링 및 Hero 애니메이션이 적용된 그리드 뷰

- **NFT Detail Page**: Full NFT info with attributes, contract details, and action buttons
- **NFT 상세 페이지**: 속성, 컨트랙트 정보, 액션 버튼이 포함된 전체 NFT 정보

- **WalletConnect v2**: Full WalletConnect v2 integration with session management and dApp pairing
- **WalletConnect v2**: 세션 관리 및 dApp 페어링이 포함된 WalletConnect v2 전체 통합

- **Send Transactions**: ETH transfer with gas estimation and transaction confirmation
- **송금 기능**: 가스 추정 및 트랜잭션 확인이 포함된 ETH 전송

- **Real Blockchain Integration**: Web3 client for fetching real ETH/ERC-20 balances
- **실제 블록체인 통합**: 실제 ETH/ERC-20 잔액 조회를 위한 Web3 클라이언트

- **Settings Page**: App configuration with network selection and security options
- **설정 페이지**: 네트워크 선택 및 보안 옵션이 포함된 앱 설정

- **Secure Storage**: PIN/Biometric authentication with encrypted wallet storage
- **보안 저장소**: 암호화된 지갑 저장소와 PIN/생체 인증

### Design Highlights / 디자인 특징

- Dark mode only with neon cyan/purple accent colors
- 네온 시안/퍼플 강조 색상이 적용된 다크 모드 전용 디자인

- Glassmorphism cards with blur effects
- 블러 효과가 적용된 글래스모피즘 카드

- Custom Ethereum diamond + wallet logo
- 커스텀 이더리움 다이아몬드 + 지갑 로고

- Smooth animations and transitions
- 부드러운 애니메이션과 전환 효과

- 4-tab bottom navigation (Wallet, NFTs, Connect, Settings)
- 4탭 하단 네비게이션 (지갑, NFT, 연결, 설정)

## Tech Stack / 기술 스택

| Category / 카테고리 | Technology / 기술 |
|----------|------------|
| Framework / 프레임워크 | Flutter 3.x |
| Language / 언어 | Dart 3.10+ |
| State Management / 상태 관리 | Riverpod 2.0 |
| Navigation / 내비게이션 | GoRouter |
| Typography / 타이포그래피 | Google Fonts (Inter) |
| UI Effects / UI 효과 | Shimmer, BackdropFilter |
| Secure Storage / 보안 저장소 | flutter_secure_storage |
| QR Scanner / QR 스캐너 | mobile_scanner |
| Web3 / 블록체인 | web3dart, http |
| WalletConnect / 월렛커넥트 | walletconnect_flutter_v2 |

## Architecture / 아키텍처

This project follows **Clean Architecture** with feature-based modularization:

이 프로젝트는 기능 기반 모듈화와 함께 **클린 아키텍처**를 따릅니다:

```
lib/
├── main.dart                    # App entry point / 앱 진입점
├── core/                        # Shared infrastructure / 공유 인프라
│   ├── constants/               # App-wide constants / 앱 전역 상수
│   ├── error/                   # Error handling / 에러 처리
│   ├── router/                  # GoRouter configuration / GoRouter 설정
│   ├── theme/                   # Theme, colors, typography / 테마, 색상, 타이포그래피
│   │   ├── app_colors.dart      # Color palette / 색상 팔레트
│   │   ├── app_theme.dart       # ThemeData configuration / ThemeData 설정
│   │   ├── app_typography.dart  # Text styles / 텍스트 스타일
│   │   └── glassmorphism.dart   # Glass effect widgets / 글래스 효과 위젯
│   └── widgets/                 # Reusable components / 재사용 컴포넌트
│       ├── app_logo.dart        # Custom painted logo / 커스텀 페인팅 로고
│       └── gradient_button.dart # Primary button widget / 주요 버튼 위젯
├── features/                    # Feature modules / 기능 모듈
│   ├── auth/                    # Authentication (Lock screen) / 인증 (잠금 화면)
│   ├── splash/                  # Splash screen / 스플래시 화면
│   ├── onboarding/              # Onboarding slides / 온보딩 슬라이드
│   ├── main/                    # Main container with navigation / 내비게이션 메인 컨테이너
│   ├── dashboard/               # Wallet dashboard / 지갑 대시보드
│   ├── wallet/                  # Wallet creation/import / 지갑 생성/가져오기
│   ├── send/                    # Send transactions / 송금 기능
│   ├── nft/                     # NFT Gallery feature / NFT 갤러리 기능
│   ├── settings/                # App settings / 앱 설정
│   └── wallet_connect/          # WalletConnect v2 integration / WalletConnect v2 통합
└── shared/                      # Cross-feature code / 기능 간 공유 코드
    ├── providers/               # Global state / 전역 상태
    └── services/                # Shared services / 공유 서비스
        ├── secure_storage_service.dart  # Encrypted storage / 암호화 저장소
        ├── pin_service.dart             # PIN management / PIN 관리
        ├── biometric_service.dart       # Biometric auth / 생체 인증
        └── auth_session_service.dart    # Session management / 세션 관리
```

### Layer Dependencies / 레이어 의존성

- **Presentation** → **Domain** (uses entities, calls usecases)
- **프레젠테이션** → **도메인** (엔티티 사용, 유스케이스 호출)

- **Data** → **Domain** (implements repository interfaces)
- **데이터** → **도메인** (레포지토리 인터페이스 구현)

- **Domain** → no external dependencies (pure Dart)
- **도메인** → 외부 의존성 없음 (순수 Dart)

## Getting Started / 시작하기

### Prerequisites / 사전 요구사항

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- Git

### Installation / 설치

```bash
# Clone the repository / 저장소 복제
git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git

# Navigate to project directory / 프로젝트 디렉토리로 이동
cd Crypto-Wallet-Pro

# Install dependencies / 의존성 설치
flutter pub get

# Run the app / 앱 실행
flutter run
```

### Build Commands / 빌드 명령어

```bash
# Development / 개발
flutter run                     # Run in debug mode / 디버그 모드 실행
flutter run -d chrome           # Run on Chrome (web) / Chrome에서 실행 (웹)
flutter run -d <device_id>      # Run on specific device / 특정 기기에서 실행

# Analysis & Testing / 분석 및 테스트
flutter analyze                 # Analyze code for issues / 코드 이슈 분석
flutter test                    # Run all tests / 모든 테스트 실행
flutter test --coverage         # Run tests with coverage / 커버리지 포함 테스트 실행

# Production Builds / 프로덕션 빌드
flutter build apk --release     # Android APK
flutter build ios --release     # iOS build / iOS 빌드
flutter build web --release     # Web build / 웹 빌드
```

## Screenshots / 스크린샷

### Onboarding Flow / 온보딩 플로우
| Secure Wallet / 보안 지갑 | Connect to dApps / dApp 연결 | NFT Gallery / NFT 갤러리 |
|:-------------:|:----------------:|:-----------:|
| <img src="assets/screenshots/03_onboarding_secure.png" width="200"/> | <img src="assets/screenshots/04_onboarding_dapps.png" width="200"/> | <img src="assets/screenshots/05_onboarding_nft.png" width="200"/> |

### Wallet Setup / 지갑 설정
| Create / Import / 생성 / 가져오기 | Recovery Phrase / 복구 문구 | Import Wallet / 지갑 가져오기 |
|:---------------:|:---------------:|:-------------:|
| <img src="assets/screenshots/06_wallet_setup.png" width="200"/> | <img src="assets/screenshots/07_recovery_phrase.png" width="200"/> | <img src="assets/screenshots/08_import_wallet.png" width="200"/> |

### Main Features / 주요 기능
| Dashboard / 대시보드 | NFT Gallery / NFT 갤러리 |
|:---------:|:-----------:|
| <img src="assets/screenshots/01_dashboard.png" width="200"/> | <img src="assets/screenshots/02_nft_gallery.png" width="200"/> |

## Project Status / 프로젝트 상태

### Completed / 완료됨

- [x] Project setup and architecture / 프로젝트 설정 및 아키텍처
- [x] Dark theme with glassmorphism / 글래스모피즘이 적용된 다크 테마
- [x] Custom logo widget (CustomPainter) / 커스텀 로고 위젯
- [x] Splash screen with animations / 애니메이션이 적용된 스플래시 화면
- [x] Onboarding flow (3 slides) / 온보딩 플로우 (3 슬라이드)
- [x] Main page with bottom navigation / 하단 내비게이션이 있는 메인 페이지
- [x] Dashboard with mock data / 목 데이터가 포함된 대시보드
- [x] Balance card widget / 잔액 카드 위젯
- [x] Token list with skeleton loading / 스켈레톤 로딩이 적용된 토큰 목록
- [x] Network selector chip / 네트워크 선택기 칩
- [x] Pull-to-refresh functionality / 당겨서 새로고침 기능
- [x] Wallet creation flow (4-step wizard) / 지갑 생성 플로우 (4단계 마법사)
- [x] Mnemonic generation and display / 니모닉 생성 및 표시
- [x] Mnemonic verification system / 니모닉 검증 시스템
- [x] Wallet import with 12-word input / 12단어 입력으로 지갑 가져오기
- [x] NFT Gallery with grid view and filtering / 그리드 뷰 및 필터링이 적용된 NFT 갤러리
- [x] NFT Detail page with Hero animations / Hero 애니메이션이 적용된 NFT 상세 페이지
- [x] Custom page transitions (Slide, Scale, Hero) / 커스텀 페이지 전환
- [x] WalletConnect UI with QR scanner / QR 스캐너가 포함된 WalletConnect UI
- [x] Settings page with network selection / 네트워크 선택이 포함된 설정 페이지
- [x] Secure storage and lock flow / 보안 저장소 및 잠금 플로우
- [x] PIN setup and authentication / PIN 설정 및 인증

### Roadmap / 로드맵

- [x] Real blockchain integration (Web3/BIP-39) / 실제 블록체인 통합 (v1.4.0)
- [x] Send transactions / 송금 트랜잭션 (v1.4.0)
- [ ] Receive transactions with QR / QR 포함 수신 트랜잭션
- [x] NFT Gallery (v1.2.0) / NFT 갤러리
- [x] WalletConnect v2 integration / WalletConnect v2 통합 (v1.4.0)
- [x] QR code scanner / QR 코드 스캐너
- [ ] Transaction history / 트랜잭션 히스토리
- [x] Settings page / 설정 페이지
- [x] Biometric authentication / 생체 인증

## Dependencies / 의존성

```yaml
dependencies:
  flutter_riverpod: ^2.4.9       # State management / 상태 관리
  riverpod_annotation: ^2.3.3    # Code generation annotations / 코드 생성 어노테이션
  go_router: ^14.0.0             # Navigation / 내비게이션
  google_fonts: ^6.1.0           # Typography / 타이포그래피
  shimmer: ^3.0.0                # Loading effects / 로딩 효과
  equatable: ^2.0.5              # Value equality / 값 동등성
  flutter_secure_storage: ^9.2.4 # Secure storage / 보안 저장소
  local_auth: ^2.3.0             # Biometric auth / 생체 인증
  mobile_scanner: ^6.0.2         # QR scanner / QR 스캐너
  web3dart: ^2.7.3               # Ethereum blockchain / 이더리움 블록체인
  http: ^1.2.0                   # HTTP client for Web3 / Web3용 HTTP 클라이언트
  walletconnect_flutter_v2: ^2.3.1 # WalletConnect v2 SDK

dev_dependencies:
  flutter_lints: ^6.0.0          # Linting rules / 린팅 규칙
  riverpod_generator: ^2.3.9     # Code generation / 코드 생성
  build_runner: ^2.4.8           # Build system / 빌드 시스템
```

## Platform Support / 플랫폼 지원

| Platform / 플랫폼 | Status / 상태 |
|----------|--------|
| Android | Supported / 지원됨 |
| iOS | Supported / 지원됨 |
| Web | Supported / 지원됨 |
| macOS | Supported / 지원됨 |
| Windows | Supported / 지원됨 |
| Linux | Supported / 지원됨 |

## Branch Strategy / 브랜치 전략

This project uses a Git-flow inspired branching model:

이 프로젝트는 Git-flow에서 영감을 받은 브랜칭 모델을 사용합니다:

```
main (production / 프로덕션)
  └── develop (development / 개발)
       ├── feature/wallet-evm
       ├── feature/wallet-solana
       ├── feature/defi-swap
       └── hotfix/* (when needed / 필요시)
```

### Branch Types / 브랜치 유형

| Branch / 브랜치 | Purpose / 용도 |
|--------|---------|
| `main` | Production-ready code / 프로덕션 준비 코드 |
| `develop` | Integration branch for features / 기능 통합 브랜치 |
| `feature/*` | New feature development / 새 기능 개발 |
| `hotfix/*` | Emergency production fixes / 긴급 프로덕션 수정 |
| `release/*` | Release preparation / 릴리스 준비 |

### Quick Start for Contributors / 기여자를 위한 빠른 시작

```bash
# Clone and setup / 복제 및 설정
git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git
cd Crypto-Wallet-Pro
git checkout develop

# Create feature branch / 기능 브랜치 생성
git checkout -b feature/your-feature-name

# After development, push and create PR to develop
# 개발 후, 푸시하고 develop으로 PR 생성
git push -u origin feature/your-feature-name
```

For detailed contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

자세한 기여 가이드라인은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

## Contributing / 기여하기

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for details on:

기여를 환영합니다! 다음 내용에 대한 자세한 사항은 [Contributing Guide](CONTRIBUTING.md)를 참조하세요:

- Git workflow and branch strategy / Git 워크플로우 및 브랜치 전략
- Commit message conventions / 커밋 메시지 컨벤션
- Pull request guidelines / Pull Request 가이드라인
- Code review process / 코드 리뷰 프로세스

### Quick Steps / 빠른 단계

1. Fork the repository / 저장소 포크
2. Create your feature branch from `develop` / `develop`에서 기능 브랜치 생성
3. Follow our commit conventions / 커밋 컨벤션 준수
4. Push and create a Pull Request to `develop` / 푸시 후 `develop`으로 PR 생성

## Development Log / 개발 로그

### 2025-12-10 - Web3 Integration & Send Feature (v1.4.0)

**Session Summary**: 실제 블록체인 통합 및 송금 기능 구현 완료

#### Implementation Phases / 구현 단계

| Phase / 단계 | Description / 설명 | Status / 상태 |
|-------|-------------|--------|
| Phase 9 | Web3 Client Integration / Web3 클라이언트 통합 | ✅ Completed / 완료 |
| Phase 10 | Real Balance Fetching / 실시간 잔액 조회 | ✅ Completed / 완료 |
| Phase 11 | Send Transaction Feature / 송금 기능 | ✅ Completed / 완료 |
| Phase 12 | WalletConnect v2 Service / WalletConnect v2 서비스 | ✅ Completed / 완료 |

#### Key Features / 주요 기능

- **Web3 Client Provider**: Configurable RPC endpoints for Mainnet/Sepolia
- **Web3 클라이언트 프로바이더**: 메인넷/세폴리아용 설정 가능한 RPC 엔드포인트

- **Balance Remote Datasource**: Real ETH and ERC-20 balance fetching via web3dart
- **잔액 원격 데이터소스**: web3dart를 통한 실제 ETH 및 ERC-20 잔액 조회

- **Send Page**: Full transaction flow with address input, amount, gas estimation
- **송금 페이지**: 주소 입력, 금액, 가스 추정이 포함된 전체 트랜잭션 플로우

- **Transaction Repository**: Clean architecture implementation for transactions
- **트랜잭션 레포지토리**: 트랜잭션을 위한 클린 아키텍처 구현

- **WalletConnect Service**: Full WalletConnect v2 SDK integration with pairing and session management
- **WalletConnect 서비스**: 페어링 및 세션 관리가 포함된 WalletConnect v2 SDK 전체 통합

- **Network Provider**: Global network state management for multi-chain support
- **네트워크 프로바이더**: 멀티체인 지원을 위한 전역 네트워크 상태 관리

#### New Files / 신규 파일

```
lib/core/constants/env_config.dart          # Environment configuration / 환경 설정
lib/core/network/web3_client_provider.dart  # Web3 client / Web3 클라이언트
lib/shared/providers/network_provider.dart  # Network state / 네트워크 상태
lib/features/dashboard/data/               # Balance data layer / 잔액 데이터 레이어
lib/features/send/                         # Complete send feature / 송금 기능 전체
lib/features/wallet_connect/data/services/ # WalletConnect service / WC 서비스
```

---

### 2024-12-10 - Secure Storage & Lock Flow (v1.3.0)

**Session Summary**: 보안 저장소 및 잠금 플로우 구현 완료

#### Implementation Phases / 구현 단계

| Phase / 단계 | Description / 설명 | Status / 상태 |
|-------|-------------|--------|
| Phase 6 | WalletConnect UI with QR Scanner / QR 스캐너 포함 WalletConnect UI | ✅ Completed / 완료 |
| Phase 7 | Settings Page UI / 설정 페이지 UI | ✅ Completed / 완료 |
| Phase 8 | Secure Storage & Lock Flow / 보안 저장소 및 잠금 플로우 | ✅ Completed / 완료 |

#### Key Features / 주요 기능

- **Secure Storage**: Encrypted wallet storage using flutter_secure_storage
- **보안 저장소**: flutter_secure_storage를 사용한 암호화된 지갑 저장소

- **PIN Authentication**: 6-digit PIN setup and verification
- **PIN 인증**: 6자리 PIN 설정 및 검증

- **Biometric Auth**: Fingerprint/Face ID support via local_auth
- **생체 인증**: local_auth를 통한 지문/Face ID 지원

- **Lock Screen**: Automatic lock after app pause with unlock flow
- **잠금 화면**: 앱 일시정지 후 자동 잠금 및 잠금 해제 플로우

- **Session Management**: Auth session tracking with auto-lock timeout
- **세션 관리**: 자동 잠금 타임아웃과 인증 세션 추적

---

### 2024-12-02 - NFT Gallery Implementation (v1.2.0)

**Session Summary**: Skeleton-First 방식으로 NFT Gallery UI 전체 구현 완료

#### Implementation Phases / 구현 단계

| Phase / 단계 | Description / 설명 | Status / 상태 |
|-------|-------------|--------|
| Phase 1 | Entity + Mock Provider / 엔티티 + 목 프로바이더 | ✅ Completed / 완료 |
| Phase 2 | Gallery UI (Grid, Filter, Shimmer) / 갤러리 UI | ✅ Completed / 완료 |
| Phase 3 | Detail Page UI (Hero, Attributes) / 상세 페이지 UI | ✅ Completed / 완료 |
| Phase 4 | Integration & Polishing / 통합 및 다듬기 | ✅ Completed / 완료 |

#### Key Features / 주요 기능

- **Filtering**: All / ERC-721 / ERC-1155 filter tabs with count badges
- **필터링**: 개수 배지가 포함된 전체 / ERC-721 / ERC-1155 필터 탭

- **Hero Animation**: Smooth image transition from grid to detail (400ms)
- **Hero 애니메이션**: 그리드에서 상세로 부드러운 이미지 전환 (400ms)

- **Edge Cases**: Empty image placeholder, fallback names, error states
- **예외 처리**: 빈 이미지 플레이스홀더, 대체 이름, 에러 상태

- **Token Standards**: Full support for ERC-721 and ERC-1155 with quantity display
- **토큰 표준**: ERC-721 및 ERC-1155 완전 지원 (수량 표시 포함)

---

### 2024-12-02 - Wallet UI Implementation (Phase 5)

**Session Summary**: Skeleton-First 방식으로 Wallet UI 구현

#### Implemented Features / 구현된 기능

| Feature / 기능 | Description / 설명 |
|---------|-------------|
| Wallet Provider / 지갑 프로바이더 | Riverpod StateNotifier for wallet state / 지갑 상태 관리 |
| Create Wallet / 지갑 생성 | 4-step creation wizard / 4단계 생성 마법사 |
| Import Wallet / 지갑 가져오기 | 12-word recovery input / 12단어 복구 입력 |
| Mnemonic Components / 니모닉 컴포넌트 | Grid display, input, word chip widgets / 그리드, 입력, 워드 칩 위젯 |

#### Key Technical Decisions / 주요 기술 결정

- **State Management / 상태 관리**: Riverpod StateNotifier pattern
- **Navigation / 내비게이션**: GoRouter with slide transitions
- **UI Pattern / UI 패턴**: Multi-step wizard with AnimatedSwitcher
- **Verification / 검증**: Random 3-word verification from 12-word mnemonic

---

## License / 라이선스

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

이 프로젝트는 MIT 라이선스에 따라 라이선스가 부여됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## Acknowledgments / 감사의 말

- Design inspired by modern crypto wallet apps
- 현대적인 암호화폐 지갑 앱에서 영감을 받은 디자인

- Built with Flutter and love
- Flutter와 사랑으로 제작됨