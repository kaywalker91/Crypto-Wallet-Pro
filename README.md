# Crypto Wallet Pro

![Project Banner](assets/screenshots/01_dashboard.png)

**Crypto Wallet Pro**는 Flutter로 개발된 차세대 암호화폐 지갑 애플리케이션입니다. 강력한 보안, 현대적인 글래스모피즘(Glassmorphism) 디자인, 그리고 직관적인 사용자 경험을 제공합니다.

---

## 📖 목차
- [주요 기능](#-주요-기능)
- [스크린샷](#-스크린샷)
- [기술 스택](#-기술-스택)
- [아키텍처](#-아키텍처)
- [시작하기](#-시작하기)
- [프로젝트 상태](#-프로젝트-상태)
- [기여하기](#-기여하기)
- [라이선스](#-라이선스)

---

## ✨ 주요 기능

### 🔐 지갑 관리
- **안전한 지갑 생성**: 니모닉(Mnemonic) 기반의 지갑 생성 및 3단계 검증 시스템
- **지갑 가져오기**: 12단어 복구 문구를 통한 지갑 복원 (붙여넣기 지원)
- **이중 보안**: PIN 번호 및 생체 인증(지문/Face ID), 암호화된 저장소

### 💸 핵심 기능
- **멀티 네트워크**: 메인넷(Mainnet) 및 테스트넷(Testnet) 간의 손쉬운 전환
- **트랜잭션**: 가스비(Gas) 자동 추정 및 실시간 ETH/ERC-20 토큰 전송
- **실시간 데이터**: Web3 클라이언트를 통한 실시간 잔액 및 데이터 조회
- **WalletConnect v2**: QR 코드 스캔을 통한 dApp 연결 및 세션 관리

### 🎨 UI/UX 디자인
- **글래스모피즘**: 블러 효과와 네온 컬러를 활용한 세련된 다크 테마
- **NFT 갤러리**: ERC-721/1155 지원, 필터링 및 Hero 애니메이션
- **인터랙티브**: 부드러운 페이지 전환 및 스와이프 제스처(Pull-to-Refresh)

---

## 📸 스크린샷

### 온보딩 (Onboarding)
| 보안 | dApps | NFT |
|:---:|:---:|:---:|
| <img src="assets/screenshots/03_onboarding_secure.png" width="200"/> | <img src="assets/screenshots/04_onboarding_dapps.png" width="200"/> | <img src="assets/screenshots/05_onboarding_nft.png" width="200"/> |

### 지갑 설정 (Wallet Setup)
| 지갑 생성 | 복구 구문 | 지갑 가져오기 |
|:---:|:---:|:---:|
| <img src="assets/screenshots/06_wallet_setup.png" width="200"/> | <img src="assets/screenshots/07_recovery_phrase.png" width="200"/> | <img src="assets/screenshots/08_import_wallet.png" width="200"/> |

### 메인 기능 (Main Features)
| 대시보드 | NFT 갤러리 |
|:---:|:---:|
| <img src="assets/screenshots/01_dashboard.png" width="200"/> | <img src="assets/screenshots/02_nft_gallery.png" width="200"/> |

---

## 🛠 기술 스택

| 분류 | 기술 |
|------|------|
| **프레임워크** | Flutter 3.x, Dart 3.10+ |
| **상태 관리** | Riverpod 2.0 (Annotations) |
| **라우팅** | GoRouter |
| **블록체인** | Web3Dart, WalletConnect Flutter v2 |
| **저장소** | Flutter Secure Storage |
| **보안** | Local Auth (생체 인증), Encrypted Shared Preferences |
| **UI 도구** | Google Fonts (Inter), Shimmer, Mobile Scanner |

---

## 🏗 아키텍처

이 프로젝트는 **Clean Architecture**와 **기능 기반 모듈화(Feature-based Modularization)** 원칙을 따릅니다.

```
lib/
├── core/            # 공통 인프라 (에러, 네트워크, 테마 등)
├── features/        # 기능별 모듈 (Auth, Wallet, Send, NFT 등)
│   ├── data/        # 데이터 소스 및 레포지토리 구현
│   ├── domain/      # 엔티티, 유스케이스, 레포지토리 인터페이스
│   └── presentation/# UI 위젯 및 상태 관리 (Providers)
└── shared/          # 전역 공유 코드 (서비스, 유틸리티)
```

### 레이어별 의존성
- **Presentation** → **Domain** 의존 (엔티티 사용, 유스케이스 호출)
- **Data** → **Domain** 구현 (레포지토리 인터페이스 구현)
- **Domain** → 외부 의존성 없음 (순수 Dart)

---

## 🚀 시작하기

### 사전 요구사항
- **Flutter SDK**: 3.10.0 이상
- **Dart SDK**: 3.10.0 이상
- **Android Studio** 또는 **VS Code**

### 설치

1. **저장소 복제**
   ```bash
   git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git
   cd Crypto-Wallet-Pro
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **앱 실행**
   ```bash
   flutter run
   ```

### 빌드
```bash
# Release APK (Android)
flutter build apk --release

# iOS 빌드
flutter build ios --release
```

---

## 📊 프로젝트 상태

| 기능 | 상태 | 설명 |
|------|------|------|
| 프로젝트 설정 | ✅ 완료 | 기본 아키텍처 및 테마 설정 |
| 지갑 핵심 기능 | ✅ 완료 | 지갑 생성, 가져오기, 니모닉 관리 |
| 보안 | ✅ 완료 | PIN, 생체 인증, 보안 저장소 |
| 대시보드 | ✅ 완료 | 실시간 잔액, 토큰 리스트 |
| NFT | ✅ 완료 | 갤러리, 상세 보기, ERC-721/1155 지원 |
| Web3 연동 | ✅ 완료 | 송금(Send), 가스비 추정 |
| WalletConnect | ✅ 완료 | v2 연동, QR 스캔 |
| 수신 기능 | ✅ 완료 | QR 코드 생성 및 주소 공유 |
| 트랜잭션 내역 | ✅ 완료 | 거래 내역 조회 및 상세 정보 |

---

## 🤝 기여하기

기여는 언제나 환영합니다! 상세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 확인해주세요.

1. 프로젝트를 **Fork** 합니다.
2. 기능 브랜치를 생성합니다. (`git checkout -b feature/amazing-feature`)
3. 변경 사항을 **커밋** 합니다. (`git commit -m 'Add: amazing feature'`)
4. 브랜치에 **Push** 합니다. (`git push origin feature/amazing-feature`)
5. **Pull Request**를 생성합니다.

---

## 📝 라이선스

이 프로젝트는 **MIT 라이선스** 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
