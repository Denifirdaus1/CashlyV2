# Repository Guidelines

## Project Structure & Module Organization
The Flutter entry point sits in `lib/main.dart`, which wires up the root widget in `lib/app.dart`. Code follows a clean architecture split: dependency injection and global state live in `lib/application/`, configuration helpers (Supabase, env) stay under `lib/core/`, `lib/domain/` holds models plus repository contracts, `lib/infrastructure/` contains Supabase-backed adapters, and UI flows reside inside `lib/presentation/` (subfolders such as `cashflow/`, `home/`, and `savings/`). Cross-platform scaffolding remains in the platform folders (`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`), assets live under `assets/`, and every production feature should be mirrored with tests in `test/`.

## Build, Test, and Development Commands
- `flutter pub get` — install or update packages listed in `pubspec.yaml`.
- `flutter analyze` — enforce the lints configured in `analysis_options.yaml`.
- `dart format lib test` — format Dart sources with the standard 2-space style.
- `flutter run -d chrome` — launch the app locally with hot reload for fast UI loops.
- `flutter test` — execute unit and widget suites.
- `flutter build apk --release` — produce the distributable Android binary; swap the platform flag for other targets.

## Coding Style & Naming Conventions
Adhere to `flutter_lints`: prefer 2-space indentation, trailing commas in widget trees, and `const` constructors whenever practical. Files and directories use `snake_case` (`group_savings_view_detail.dart`), while classes, enums, and typedefs use `UpperCamelCase`. Keep provider names descriptive (e.g., `cashRepositoryProvider`, `HomeModeNotifier`) and colocate state with the feature module to avoid import sprawl. Break long widget trees into private helpers to keep `build` methods scannable.

## Testing Guidelines
Place specs in `test/`, replicating the folder tree from `lib/` so relative imports remain simple. Name files `*_test.dart` and rely on `flutter_test` plus Riverpod `ProviderContainer` harnesses to exercise notifiers and repositories. Supabase adapters should be validated with fakes or mock clients to avoid network usage. Run `flutter test --coverage` before opening a PR and ensure assertions cover both success and error paths, especially around formatting, validation, and Supabase mutations.

## Commit & Pull Request Guidelines
Git history shows Conventional Commits (`fix: rls policies...`, `style: apply mint theme...`), so keep the `type(scope?): summary` structure under 72 characters. Describe the motivation in the body, mention linked issues, and enumerate migrations or config changes. PRs should include: a short summary, test evidence (`flutter analyze` + `flutter test` output), screenshots or recordings for UI updates, and any required env/secret notes. Keep PRs narrow in scope; split large work across stacked branches when necessary.

## Security & Configuration Tips
Supabase credentials load from compile-time envs via `String.fromEnvironment` in `lib/core/env.dart`. Never commit real project keys—pass them using `--dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...` for `flutter run`/`flutter build`, and mirror the values in CI secrets. Audit logs for sensitive payloads before merging, and avoid storing user data under `assets/` or in version control. Rotate Supabase keys in tandem with config updates and document any required manual steps in the PR.