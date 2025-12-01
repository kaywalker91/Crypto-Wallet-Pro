# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS)
flutter build ios --release

# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

## Architecture

This project follows **Clean Architecture** with feature-based modularization.

### Directory Structure

```
lib/
├── main.dart              # App entry point
├── core/                  # Shared infrastructure
│   ├── constants/         # App-wide constants
│   ├── error/             # Error handling, exceptions, failures
│   ├── network/           # HTTP client, API configuration
│   ├── theme/             # App theming, colors, typography
│   ├── utils/             # Utility functions, extensions
│   └── widgets/           # Reusable UI components
├── features/              # Feature modules (each follows Clean Architecture)
│   ├── dashboard/
│   ├── nft/
│   ├── send/
│   ├── wallet/
│   └── wallet_connect/
└── shared/                # Cross-feature shared code
    ├── providers/         # State management providers
    └── services/          # Shared services
```

### Feature Module Structure (Clean Architecture)

Each feature in `lib/features/` follows this structure:

```
feature_name/
├── data/                  # Data layer (external)
│   ├── datasources/       # Remote/local data sources
│   ├── models/            # DTOs, JSON serialization
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer (business logic)
│   ├── entities/          # Business objects
│   ├── repositories/      # Repository interfaces (contracts)
│   └── usecases/          # Business logic operations
└── presentation/          # Presentation layer (UI)
    ├── pages/             # Screen widgets
    ├── providers/         # State management (likely Riverpod)
    └── widgets/           # Feature-specific UI components
```

### Layer Dependencies

- **Presentation** → depends on **Domain** (uses entities, calls usecases)
- **Data** → implements **Domain** (implements repository interfaces)
- **Domain** → no external dependencies (pure Dart)

### Key Patterns

- Repository pattern: Domain defines interfaces, Data implements them
- Use cases: Single-responsibility business operations in domain layer
- State management: Provider-based (check `providers/` directories)
- The `wallet_connect` feature includes an additional `services/` directory for WalletConnect protocol integration

## Current Dependencies

- Dart SDK: ^3.10.1
- flutter_lints: ^6.0.0 (linting)
- Uses Material Design icons

## Platform Support

Multi-platform Flutter project: Android, iOS, Web, Linux, macOS, Windows
