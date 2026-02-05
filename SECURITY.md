# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow responsible disclosure practices.

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email your findings to: `security@example.com`
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours of your report
- **Initial Assessment**: Within 7 days
- **Resolution Timeline**: Depends on severity (Critical: 7 days, High: 14 days, Medium: 30 days)
- **Credit**: We'll credit you in the release notes (unless you prefer anonymity)

## Security Features

Crypto Wallet Pro implements enterprise-grade security:

### Defense-in-Depth Architecture

| Layer | Protection |
|-------|------------|
| Memory Security | Secure memory clearing, minimal exposure time |
| UI Security | Screenshot/recording protection, overlay detection |
| App Security | Root/jailbreak detection, integrity verification |
| Access Control | Biometric auth, PIN protection, session management |
| Encryption | AES-256-GCM, PBKDF2-SHA256 (100K iterations) |

### Key Security Implementations

- **Private Key Storage**: Platform-level secure storage (Android Keystore / iOS Keychain)
- **Double Encryption**: App-level + Platform-level encryption
- **BIP Standards**: BIP-39 mnemonic, BIP-32/44 HD wallet derivation
- **Biometric Integration**: Hardware-backed fingerprint/Face ID

### Security Documentation

For detailed security architecture and implementation guides:

- [Screenshot Protection Guide](docs/security/SCREENSHOT_PROTECTION_GUIDE.md)
- [Device Integrity Checks](docs/security/SECURITY_DEVICE_INTEGRITY.md)
- [Security Summary](docs/security/SCREENSHOT_PROTECTION_SUMMARY.md)

## Security Best Practices for Users

1. **Never share** your recovery phrase with anyone
2. **Enable biometric authentication** for enhanced security
3. **Keep your app updated** to receive security patches
4. **Verify transactions** carefully before signing
5. **Use secure networks** when accessing your wallet
