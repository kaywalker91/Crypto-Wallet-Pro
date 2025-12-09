# Repository Guidelines

## Project Structure & Module Organization
- `lib/core`: shared foundations (constants, router, theme, widgets, utils).
- `lib/features/<feature>`: clean-architecture modules with `domain/`, `presentation/` (pages, providers, widgets), and data where needed.
- `lib/shared`: cross-feature providers/services.
- `assets/`: images, fonts, and screenshots referenced in `pubspec.yaml`.
- `test/`: mirrors `lib/` paths; add `*_test.dart` alongside feature folders.
- Platform shells live under `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`; keep changes minimal unless platform-specific work.

## Build, Test, and Development Commands
- `flutter pub get` — install Dart/Flutter dependencies.
- `flutter run` — launch in debug on the active device; use `-d chrome` for web or a specific device ID.
- `flutter analyze` — static analysis using `flutter_lints`.
- `flutter test` — run unit/widget tests; add `--coverage` to generate coverage.
- `flutter build apk --release` / `flutter build ios --release` / `flutter build web --release` — production builds per platform.

## Coding Style & Naming Conventions
- Follow Dart defaults: 2-space indent, trailing commas for multiline args, `dart format .` before PRs.
- Files and directories use `snake_case.dart`; classes and enums use `PascalCase`; methods/variables use `camelCase`.
- Keep widgets small and composable; prefer stateless/stateful widgets over logic-heavy build methods.
- Riverpod: suffix providers with `Provider` (e.g., `balanceProvider`), keep state classes immutable (`const` where possible).
- Keep feature boundaries clean: UI in `presentation`, pure logic in `domain`, shared widgets/utilities in `core`/`shared`.

## Testing Guidelines
- Place tests under `test/<feature>/` mirroring `lib/features/<feature>/`.
- Name tests after subject behavior (`dashboard_page_test.dart`, `wallet_service_test.dart`).
- Aim to cover critical flows: routing, provider logic, serialization, and UI states.
- Run `flutter test` locally before PRs; verify coverage for new logic with `flutter test --coverage`.

## Commit & Pull Request Guidelines
- Branching: start from `develop`; use `feature/<scope>-<summary>`, `hotfix/<issue>`, or `release/v<semver>`.
- Commits follow Conventional Commits (`feat(wallet): add mnemonic verification`, `fix(nft): handle empty attributes`).
- PRs target `develop`, include a concise summary, linked issue if applicable, and screenshots for UI-facing changes.
- Confirm `flutter analyze` and `flutter test` are green before requesting review; note any TODOs or follow-ups explicitly.

## Security & Configuration Tips
- Never commit secrets, keystores, or `.env`-style files; prefer local env configuration or CI secrets.
- Validate third-party packages before adding them to `pubspec.yaml` and document why they are needed.
- Keep API keys and private endpoints out of source; use `--dart-define` when integrating runtime config.
