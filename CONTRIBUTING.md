# Contributing to Crypto Wallet Pro

Thank you for your interest in contributing to Crypto Wallet Pro! This document provides guidelines and information for contributors.

## Table of Contents

- [Git Workflow](#git-workflow)
- [Branch Strategy](#branch-strategy)
- [Commit Convention](#commit-convention)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Code Review Guidelines](#code-review-guidelines)
- [Development Setup](#development-setup)

---

## Git Workflow

We follow a Git-flow inspired branching model to maintain a clean and organized codebase.

### Branch Structure

```
main (production)
  └── develop
       ├── feature/wallet-evm
       ├── feature/wallet-solana
       ├── feature/defi-swap
       ├── feature/nft-gallery
       ├── feature/wallet-connect
       └── hotfix/security-patch (when needed)
```

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        main (production)                     │
│  ═══════════════════════════════════════════════════════════ │
│         ↑                              ↑                     │
│      merge                          merge                    │
│         │                              │                     │
│  ┌──────┴──────┐              ┌────────┴────────┐           │
│  │   release   │              │     hotfix      │           │
│  │   v1.1.0    │              │ security-patch  │           │
│  └──────┬──────┘              └────────┬────────┘           │
│         ↑                              │                     │
│      merge                          merge                    │
│         │                              ↓                     │
│  ═══════╧══════════════════════════════╧═══════════════════ │
│                        develop                               │
│         ↑              ↑              ↑                     │
│      merge          merge          merge                    │
│         │              │              │                     │
│  ┌──────┴──────┐ ┌────┴────┐ ┌───────┴───────┐            │
│  │   feature/  │ │ feature/│ │   feature/    │            │
│  │ wallet-evm  │ │defi-swap│ │ wallet-solana │            │
│  └─────────────┘ └─────────┘ └───────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

---

## Branch Strategy

### Branch Types

| Branch | Purpose | Base | Merge Target |
|--------|---------|------|--------------|
| `main` | Production-ready code | - | - |
| `develop` | Integration branch for features | `main` | `main` (via release) |
| `feature/*` | New feature development | `develop` | `develop` |
| `hotfix/*` | Emergency production fixes | `main` | `main` & `develop` |
| `release/*` | Release preparation | `develop` | `main` & `develop` |

### Naming Convention

```bash
# Feature branches
feature/[scope]-[description]
  feature/wallet-evm          # EVM wallet implementation
  feature/defi-swap           # DeFi swap functionality
  feature/nft-gallery         # NFT gallery feature

# Hotfix branches
hotfix/[issue-type]-[description]
  hotfix/security-patch       # Security vulnerability fix
  hotfix/critical-bug         # Critical bug fix

# Release branches
release/v[major].[minor].[patch]
  release/v1.1.0              # Version 1.1.0 release
  release/v2.0.0              # Version 2.0.0 release
```

### Working with Branches

#### Creating a Feature Branch

```bash
# Ensure you're on develop
git checkout develop
git pull origin develop

# Create and switch to feature branch
git checkout -b feature/your-feature-name

# Push to remote
git push -u origin feature/your-feature-name
```

#### Creating a Hotfix Branch

```bash
# Ensure you're on main
git checkout main
git pull origin main

# Create and switch to hotfix branch
git checkout -b hotfix/issue-description

# After fixing, merge to both main and develop
```

---

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(wallet): add HD wallet generation` |
| `fix` | Bug fix | `fix(send): resolve gas estimation error` |
| `docs` | Documentation | `docs: update API documentation` |
| `style` | Code style (formatting, etc.) | `style: apply dart format` |
| `refactor` | Code refactoring | `refactor(dashboard): extract balance widget` |
| `test` | Adding/updating tests | `test(wallet): add mnemonic validation tests` |
| `chore` | Build/config changes | `chore: update dependencies` |
| `perf` | Performance improvement | `perf(nft): optimize image caching` |
| `security` | Security-related changes | `security(wallet): encrypt private keys` |
| `ci` | CI/CD changes | `ci: add GitHub Actions workflow` |

### Scopes

Based on project modules:

```
wallet, dashboard, send, nft, wallet-connect, core, theme, router, config
```

### Examples

```bash
# Feature commit
git commit -m "feat(wallet): implement BIP39 mnemonic generation"

# Bug fix with body
git commit -m "fix(send): resolve transaction fee calculation

The fee was being calculated with wrong decimals.
Added proper decimal handling for ETH and ERC20 tokens.

Fixes #42"

# Breaking change
git commit -m "feat(api)!: change wallet response structure

BREAKING CHANGE: wallet API now returns nested account object"
```

---

## Pull Request Guidelines

### Before Creating a PR

- [ ] Ensure your branch is up to date with `develop`
- [ ] Run `flutter analyze` and fix any issues
- [ ] Run `flutter test` and ensure all tests pass
- [ ] Self-review your code changes
- [ ] Update documentation if needed

### PR Title Format

Follow the same convention as commit messages:

```
feat(wallet): add EVM wallet creation flow
fix(dashboard): resolve balance refresh issue
```

### PR Template

```markdown
## Summary
<!-- Brief description of the changes -->

## Changes
- [ ] Change 1
- [ ] Change 2
- [ ] Change 3

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### PR Process

1. Create PR from `feature/*` to `develop`
2. Request review from at least 1 team member
3. Address review comments
4. Ensure CI checks pass
5. Squash and merge (preferred) or merge commit

---

## Code Review Guidelines

### For Reviewers

#### What to Look For

1. **Code Quality**
   - Clean Architecture compliance
   - SOLID principles adherence
   - Proper error handling
   - No code duplication

2. **Security**
   - No exposed secrets or keys
   - Proper input validation
   - Secure data handling

3. **Performance**
   - No unnecessary rebuilds (Flutter)
   - Efficient state management
   - Proper async handling

4. **Testing**
   - Adequate test coverage
   - Edge cases handled
   - Meaningful test names

#### Review Feedback Prefixes

| Prefix | Meaning |
|--------|---------|
| `[blocking]` | Must be fixed before merge |
| `[suggestion]` | Optional improvement |
| `[question]` | Need clarification |
| `[nitpick]` | Minor style preference |
| `[praise]` | Positive feedback |

### For Authors

- Respond to all comments
- Explain your reasoning when disagreeing
- Mark resolved conversations
- Request re-review after making changes

---

## Development Setup

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- Git

### Getting Started

```bash
# Clone the repository
git clone https://github.com/kaywalker91/Crypto-Wallet-Pro.git
cd Crypto-Wallet-Pro

# Checkout develop branch
git checkout develop

# Install dependencies
flutter pub get

# Run code generation (if using build_runner)
flutter pub run build_runner build

# Run the app
flutter run
```

### Code Quality Commands

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

---

## Questions?

If you have questions about contributing, please:

1. Check existing issues and PRs
2. Create a new issue with the `question` label
3. Reach out to maintainers

Thank you for contributing!
