Product Requirements Document (PRD): Crypto Wallet Pro

1. 프로젝트 개요 (Project Overview)

프로젝트명: Crypto Wallet Pro (가칭: EtherFlow)

프로젝트 유형: 학습 및 포트폴리오용 모바일 암호화폐 지갑 (Toy Project)

플랫폼: Flutter (Android / iOS)

개발 기간: 2025.12.01 ~ 2025.12.31 (4주)

목표: * Ethereum 기반의 비수탁(Non-custodial) 지갑 구현.

Riverpod 2.0과 Clean Architecture를 완벽하게 적용하여 유지보수 가능한 코드베이스 구축.

Web3 프로토콜(WalletConnect, ENS) 연동을 통한 고급 기능 구현 능력 증명.

2. 핵심 기술 스택 (Tech Stack Strategy)

이 프로젝트는 **"기술적 깊이"**를 보여주는 것이 목적이므로, 아래 스택을 엄격하게 준수합니다.

Framework: Flutter (Latest Stable)

Language: Dart 3.x (Records, Pattern Matching 적극 활용)

State Management: Riverpod 2.0 (Code Generation)

AsyncNotifier, StreamProvider를 활용한 리액티브 프로그래밍 구현.

Architecture: Clean Architecture

Presentation -> Domain (Pure Dart) -> Data (Repository Impl, Data Sources) 계층 분리 엄수.

Core Blockchain Libs:

web3dart: 이더리움 트랜잭션 서명 및 RPC 통신.

walletconnect_flutter_v2: dApp 연결 (필수 킬러 기능).

bip39, bip32: 니모닉 생성 및 HD 지갑 키 파생.

Local Storage:

flutter_secure_storage: Private Key, Mnemonic 암호화 저장 (보안 필수).

hive or shared_preferences: 사용자 설정 및 비휘발성 캐시 데이터.

Network: dio (Interceptor를 통한 에러 핸들링 및 로깅).

3. 주요 기능 명세 (Feature Specifications)

3.1. 지갑 관리 (Wallet Management)

지갑 생성 (Create): * BIP-39 표준 12단어 니모닉(Seed Phrase) 생성.

사용자에게 니모닉 백업 유도 UI 구현.

지갑 가져오기 (Import): * 기존 니모닉 입력을 통한 지갑 복구.

m/44'/60'/0'/0/0 경로를 통한 Private Key 파생.

보안: * 앱 실행 시 생체 인증(Biometric) 또는 PIN 번호 요구.

Private Key는 절대 서버로 전송하지 않음 (Local Only).

3.2. 대시보드 및 자산 조회 (Dashboard)

네트워크 전환: Ethereum Mainnet <-> Sepolia Testnet (개발 시 Sepolia 권장).

잔액 조회: Native ETH 잔액 실시간 표시 (Pull-to-refresh).

토큰 리스트: 보유 중인 ERC-20 토큰 자동 감지 및 잔액 표시 (Alchemy/Infura API 활용).

ENS 지원: 지갑 주소 대신 user.eth 형태의 도메인 표시 및 역방향 조회(Reverse Resolution).

3.3. 송금 (Send Transaction)

주소 입력: * QR 코드 스캔.

ENS 도메인 입력 시 주소 자동 변환 (Resolution).

가스비(Gas Fee) 추정: * EIP-1559(Type 2) 트랜잭션 지원.

Low/Medium/High 옵션에 따른 수수료 견적 실시간 표시.

트랜잭션 전송: 서명(Sign) 후 브로드캐스트.

3.4. WalletConnect v2 (Killer Feature)

기능: 외부 dApp(예: Uniswap, OpenSea 웹사이트)과 모바일 지갑 연결.

시나리오: 1. PC 브라우저에서 Uniswap 접속 -> 'Connect Wallet' 클릭 -> QR 코드 생성.
2. 앱 내 카메라로 QR 스캔 -> 세션 연결 승인.
3. dApp에서 트랜잭션 요청 -> 앱에서 팝업으로 서명 요청 승인/거절.

3.5. NFT 갤러리 (Visual)

조회: 보유 중인 ERC-721, ERC-1155 NFT 목록 그리드 뷰.

상세: NFT 이미지(IPFS/HTTP), 메타데이터, 속성(Attributes) 표시.

최적화: 이미지 캐싱(cached_network_image) 적용하여 스크롤 버벅임 방지.

4. UI/UX 디자인 가이드라인

테마: Dark Mode Only (크립토 앱의 표준, "Pro" 느낌 강조).

스타일: Glassmorphism (배경 블러 처리) 및 네온 그라디언트 포인트 컬러 사용.

인터랙션: * 송금 성공 시 Lottie 애니메이션.

숫자 변경 시 카운팅 애니메이션 (AnimatedCounter).

5. 데이터 흐름 및 아키텍처 (Data Flow)

Repository Pattern:

UI는 Provider를 구독.

Provider는 UseCase를 호출.

UseCase는 Repository 인터페이스에 의존.

RepositoryImpl이 Web3DataSource(Remote)와 LocalDataSource(Storage)를 조율.

에러 핸들링: * Functional Error Handling (fpdart의 Either 타입 추천) 또는 Custom Exception Class를 통해 UI에 명확한 에러 메시지 전달 (예: "잔액 부족", "네트워크 오류").

6. 개발 로드맵 (4주 완성 계획)

Week 1: Core Wallet (기반 공사)

프로젝트 셋팅 및 Clean Architecture 폴더 구조화.

니모닉 생성, 키 파생 로직 구현 (web3dart).

Secure Storage 연동하여 지갑 생성/저장/불러오기 완료.

목표: 앱 껐다 켜도 내 지갑 주소가 유지되어야 함.

Week 2: Blockchain Interaction (통신)

Infura 또는 Alchemy API 키 발급 및 연동.

ETH 잔액 조회 및 ERC-20 토큰 잔액 조회 구현.

송금 기능(Gas Estimation -> Sign -> Send) 구현.

목표: Sepolia 테스트넷에서 내 지갑 간 ETH 이동 성공.

Week 3: Advanced Features (고급 기능)

WalletConnect v2 연동 (가장 난이도 높음, 시간 투자 필요).

ENS 리졸버 구현 (주소 <-> 도메인 변환).

목표: Uniswap(Testnet)에 QR로 연결하여 스왑 승인해보기.

Week 4: NFT & Polish (마무리)

NFT API 연동하여 갤러리 탭 완성.

UI 디자인 고도화 (애니메이션, 폰트, 다크모드 디테일).

코드 리팩토링 및 주석 정리.

README 작성 (아키텍처 다이어그램 포함).

7. 학습 및 포트폴리오 포인트 (Key Takeaways)

면접관이 이 프로젝트를 볼 때 확인할 체크리스트입니다. 스스로 질문하며 개발하세요.

상태 관리: "비동기 데이터(블록체인)와 로컬 데이터(지갑 키)의 싱크를 어떻게 Riverpod으로 우아하게 처리했는가?"

아키텍처: "Web3 라이브러리가 교체되어도 비즈니스 로직(Domain)이 영향을 받지 않도록 분리되었는가?"

보안: "니모닉이나 Private Key가 평문으로 저장되거나 로그에 찍히는 실수는 없는가?"

UX: "블록체인의 느린 속도(Latency)를 사용자에게 로딩 인디케이터나 낙관적 업데이트(Optimistic UI)로 잘 감췄는가?"

8. API 리소스 (참고용)

Node Provider: Alchemy (추천: 무료 티어 넉넉함) 또는 Infura.

Faucet (테스트 코인): Sepolia PoW Faucet.

NFT Data: Alchemy NFT API 사용 권장.