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

## Implemented Features

### NFT Gallery (Completed)

The NFT feature follows Clean Architecture with Skeleton-First approach:

```
lib/features/nft/
├── domain/
│   └── entities/
│       ├── nft.dart               # NFT entity with ERC-721/1155 support
│       └── nft_attribute.dart     # NFT attribute (trait_type, value)
└── presentation/
    ├── pages/
    │   ├── nft_gallery_page.dart  # Grid view with filtering, pull-to-refresh
    │   └── nft_detail_page.dart   # Detail page with Hero animation
    ├── providers/
    │   └── nft_provider.dart      # Riverpod StateNotifier with mock data
    └── widgets/
        ├── nft_grid_item.dart     # Grid item with token badges
        ├── nft_loading_shimmer.dart # Loading skeleton
        ├── nft_empty_state.dart   # Empty/error states
        └── nft_attribute_chip.dart # Attribute display chip
```

### Core Utilities

```
lib/core/utils/
└── page_transitions.dart    # Custom PageRouteBuilder transitions
    ├── SlidePageRoute       # iOS-style slide + fade
    ├── ScalePageRoute       # Modal-style scale + fade
    └── HeroPageRoute        # Optimized for Hero animations (400ms)
```

## NFT-Specific Patterns

- **Hero Animations**: `Hero` tag format: `'nft_${contractAddress}_${tokenId}'`
- **Filtering**: `NftFilter` enum (all, erc721, erc1155) with `filteredNfts` getter
- **Token Standards**: `NftTokenType` enum supporting ERC-721 and ERC-1155
- **Edge Case Handling**:
  - Empty imageUrl → placeholder widget
  - Empty name → fallback to `#${tokenId}`
  - Empty collection → "Unknown Collection"

## Current Dependencies

- Dart SDK: ^3.10.1
- flutter_riverpod: ^2.4.9 (State management)
- go_router: ^14.0.0 (Navigation)
- google_fonts: ^6.1.0 (Typography)
- shimmer: ^3.0.0 (Loading effects)
- equatable: ^2.0.5 (Value equality)
- flutter_lints: ^6.0.0 (Linting)

## Platform Support

Multi-platform Flutter project: Android, iOS, Web, Linux, macOS, Windows
