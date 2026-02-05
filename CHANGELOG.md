# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added

#### Wallet Management
- Generate 12-word mnemonic phrases (BIP-39)
- Import existing wallets using seed phrases
- Private keys encrypted via `flutter_secure_storage`
- Biometric (Fingerprint/Face ID) and PIN authentication

#### Dashboard
- Real-time ETH and ERC-20 token balances
- Auto-discovery of popular tokens
- Ethereum Mainnet and Sepolia Testnet support

#### Send & Receive
- Transfer ETH and ERC-20 tokens with gas estimation
- QR code generation for receiving
- Transaction history viewing

#### NFT Gallery
- Visual NFT grid layout
- ERC-721 and ERC-1155 support
- Detailed view with attributes and collection info
- Optimized image loading with caching

#### Web3 Connectivity
- WalletConnect v2 integration
- Session management (approve/reject)
- Transaction signing

#### Security Enhancements
- Defense-in-Depth 5-layer security architecture
- AES-256-GCM double encryption
- PBKDF2-SHA256 key derivation (100K iterations)
- Screenshot/recording protection
- Root/jailbreak detection with warning dialogs
- Encrypted audit logs

### Technical
- Clean Architecture with feature-first structure
- Riverpod 2.0 state management
- GoRouter navigation with deep linking
- Alchemy API integration

### Fixed
- Bottom navigation overflow and responsive scaling
- Flutter analyze cleanup (withOpacity→withValues, MaterialState→WidgetState)
- Riverpod Ref migration
- web3dart address usage

---

## [Unreleased]

### Planned
- Multi-chain support (Polygon, BSC, Arbitrum)
- Hardware wallet integration (Ledger, Trezor)
- Token swap functionality
- Push notifications for transactions
