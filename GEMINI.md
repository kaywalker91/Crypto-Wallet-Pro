# Crypto Wallet Pro Context

## Project Overview
**Crypto Wallet Pro** is a modern, secure, and feature-rich cryptocurrency wallet application built with Flutter. It focuses on Ethereum-based assets (ETH, ERC-20 tokens, ERC-721/1155 NFTs) and features a sleek Glassmorphism UI.

### Key Features
*   **Wallet Management:** Mnemonic-based creation, 3-step verification, 12-word recovery import.
*   **Security:** Biometric authentication (Fingerprint/Face ID), PIN protection, Encrypted storage.
*   **Core Functions:** Multi-network support (Mainnet/Testnet), Real-time balance/gas estimation, Send/Receive ETH & Tokens.
*   **Web3:** WalletConnect v2 support for dApp interaction.
*   **NFTs:** Gallery with filtering and animations for ERC-721/1155.

## Technology Stack
*   **Framework:** Flutter 3.x, Dart 3.10+
*   **State Management:** Riverpod 2.0 (using `riverpod_annotation` & `riverpod_generator`)
*   **Navigation:** GoRouter
*   **Blockchain:** `web3dart`, `walletconnect_flutter_v2`, `bip39`, `bip32`
*   **Storage:** `flutter_secure_storage`
*   **UI:** Google Fonts (Inter), Shimmer effects

## Architecture
The project follows **Clean Architecture** with **Feature-based Modularization**:

```
lib/
├── core/            # Common infrastructure (constants, error, network, router, theme, utils, widgets)
├── features/        # Feature modules (auth, dashboard, history, nft, wallet, etc.)
│   ├── <feature_name>/
│   │   ├── data/        # Data sources & Repository implementations
│   │   ├── domain/      # Entities, Use cases, Repository interfaces
│   │   └── presentation/# Pages, Providers, Widgets
└── shared/          # Global shared code (providers, services)
```

## Development Guidelines

### Build & Run
*   **Install Dependencies:** `flutter pub get`
*   **Run App:** `flutter run`
*   **Code Generation:** `dart run build_runner build --delete-conflicting-outputs` (Required for Riverpod)
*   **Lint:** `flutter analyze`
*   **Test:** `flutter test`

### Coding Conventions
*   **Style:** Follow Dart standard style. Use `dart format .` before committing.
*   **Naming:**
    *   Files/Directories: `snake_case.dart`
    *   Classes/Enums: `PascalCase`
    *   Variables/Methods: `camelCase`
*   **State Management:**
    *   Use Riverpod with annotations.
    *   Suffix providers with `Provider` (e.g., `balanceProvider`).
    *   Keep state immutable.
*   **Testing:**
    *   Tests must mirror the `lib/` structure in `test/`.
    *   Filenames: `<subject>_test.dart`.

### Contribution
*   **Commits:** Follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat(wallet): add import validation`).
*   **Branches:** `feature/<name>`, `fix/<issue>`, `hotfix/<issue>`.
