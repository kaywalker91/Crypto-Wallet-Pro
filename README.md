# Crypto Wallet Pro

A modern, feature-rich cryptocurrency wallet application built with Flutter.

<p align="center">
  <img src="assets/images/logo_placeholder.png" alt="Crypto Wallet Pro Logo" width="120"/>
</p>

## Features

### Current Implementation (v1.0.0)

- **Splash Screen**: Animated logo with glassmorphism effects
- **Onboarding Flow**: 3-slide introduction showcasing key features
- **Dashboard**: Main wallet interface with balance display and token list
- **Glassmorphism UI**: Modern dark theme with frosted glass effects
- **Multi-Network Support**: Network selector for Mainnet/Testnet switching
- **Pull-to-Refresh**: Refresh wallet data with swipe gesture

### Design Highlights

- Dark mode only with neon cyan/purple accent colors
- Glassmorphism cards with blur effects
- Custom Ethereum diamond + wallet logo
- Smooth animations and transitions
- 4-tab bottom navigation (Wallet, NFTs, Connect, Settings)

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| Language | Dart 3.10+ |
| State Management | Riverpod 2.0 |
| Navigation | GoRouter |
| Typography | Google Fonts (Inter) |
| UI Effects | Shimmer, BackdropFilter |

## Architecture

This project follows **Clean Architecture** with feature-based modularization:

```
lib/
├── main.dart                    # App entry point
├── core/                        # Shared infrastructure
│   ├── constants/               # App-wide constants
│   ├── router/                  # GoRouter configuration
│   ├── theme/                   # Theme, colors, typography
│   │   ├── app_colors.dart      # Color palette
│   │   ├── app_theme.dart       # ThemeData configuration
│   │   ├── app_typography.dart  # Text styles
│   │   └── glassmorphism.dart   # Glass effect widgets
│   └── widgets/                 # Reusable components
│       ├── app_logo.dart        # Custom painted logo
│       └── gradient_button.dart # Primary button widget
├── features/                    # Feature modules
│   ├── splash/                  # Splash screen
│   ├── onboarding/              # Onboarding slides
│   ├── main/                    # Main container with navigation
│   └── dashboard/               # Wallet dashboard
│       ├── domain/
│       │   └── entities/        # Token, WalletBalance
│       └── presentation/
│           ├── pages/           # DashboardPage
│           ├── providers/       # Riverpod state
│           └── widgets/         # Balance card, Token list
└── shared/                      # Cross-feature code
    ├── providers/               # Global state
    └── services/                # Shared services
```

### Layer Dependencies

- **Presentation** → **Domain** (uses entities, calls usecases)
- **Data** → **Domain** (implements repository interfaces)
- **Domain** → no external dependencies (pure Dart)

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git

# Navigate to project directory
cd Crypto-Wallet-Pro

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Commands

```bash
# Development
flutter run                     # Run in debug mode
flutter run -d chrome           # Run on Chrome (web)
flutter run -d <device_id>      # Run on specific device

# Analysis & Testing
flutter analyze                 # Analyze code for issues
flutter test                    # Run all tests
flutter test --coverage         # Run tests with coverage

# Production Builds
flutter build apk --release     # Android APK
flutter build ios --release     # iOS build
flutter build web --release     # Web build
```

## Screenshots

| Splash | Onboarding | Dashboard |
|--------|------------|-----------|
| Animated logo with glow effect | Feature slides with skip option | Balance card with token list |

## Project Status

### Completed

- [x] Project setup and architecture
- [x] Dark theme with glassmorphism
- [x] Custom logo widget (CustomPainter)
- [x] Splash screen with animations
- [x] Onboarding flow (3 slides)
- [x] Main page with bottom navigation
- [x] Dashboard with mock data
- [x] Balance card widget
- [x] Token list with skeleton loading
- [x] Network selector chip
- [x] Pull-to-refresh functionality

### Roadmap

- [ ] Wallet creation/import
- [ ] Real blockchain integration (Web3)
- [ ] Send/Receive transactions
- [ ] NFT Gallery
- [ ] WalletConnect integration
- [ ] QR code scanner
- [ ] Transaction history
- [ ] Settings page
- [ ] Biometric authentication

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State management
  riverpod_annotation: ^2.3.3 # Code generation annotations
  go_router: ^14.0.0          # Navigation
  google_fonts: ^6.1.0        # Typography
  shimmer: ^3.0.0             # Loading effects
  equatable: ^2.0.5           # Value equality

dev_dependencies:
  flutter_lints: ^6.0.0       # Linting rules
  riverpod_generator: ^2.3.9  # Code generation
  build_runner: ^2.4.8        # Build system
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| macOS | Supported |
| Windows | Supported |
| Linux | Supported |

## Branch Strategy

This project uses a Git-flow inspired branching model:

```
main (production)
  └── develop
       ├── feature/wallet-evm
       ├── feature/wallet-solana
       ├── feature/defi-swap
       └── hotfix/* (when needed)
```

### Branch Types

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `develop` | Integration branch for features |
| `feature/*` | New feature development |
| `hotfix/*` | Emergency production fixes |
| `release/*` | Release preparation |

### Quick Start for Contributors

```bash
# Clone and setup
git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git
cd Crypto-Wallet-Pro
git checkout develop

# Create feature branch
git checkout -b feature/your-feature-name

# After development, push and create PR to develop
git push -u origin feature/your-feature-name
```

For detailed contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for details on:

- Git workflow and branch strategy
- Commit message conventions
- Pull request guidelines
- Code review process

### Quick Steps

1. Fork the repository
2. Create your feature branch from `develop`
3. Follow our commit conventions
4. Push and create a Pull Request to `develop`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Design inspired by modern crypto wallet apps
- Built with Flutter and love
