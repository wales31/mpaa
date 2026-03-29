# Week 1–2: Architecture & Contracts Baseline

This document defines the migration baseline from the current React app to Flutter so implementation parity can be measured.

## Feature modules

The Flutter codebase should align to these primary modules:

1. **auth**
   - Responsibilities: sign-in/out, auth state, role checks.
   - Current status: scaffolded in `mobile/lib/features/auth`.
2. **dashboard**
   - Responsibilities: top-level KPIs and chart summaries.
   - Current status: placeholder route at `/dashboard`.
3. **reports**
   - Responsibilities: export flows and historical filters.
   - Current status: route contract defined, screen pending.
4. **settings**
   - Responsibilities: profile display and app preferences.
   - Current status: route contract defined, screen pending.

## Layer contracts (per module)

Use this vertical slice pattern:

- `presentation/`: widgets, route entry points, view models/providers.
- `domain/`: entities + use cases (pure Dart).
- `data/`: Firebase/REST implementations and DTO mapping.

## App-wide patterns

### Error handling

- Global unhandled capture through `ErrorHandler.installGlobalHandlers()`.
- Feature/domain errors should throw `AppException` with machine-readable `code`.
- UI fallback should use `ErrorView` for recoverable errors.

### Logging

- Use `AppLogger` with levels: `debug`, `info`, `warning`, `error`.
- Log every network request + request failures in Dio interceptors.

### Analytics

- Use `AnalyticsService` abstraction.
- Track at minimum:
  - `screen_view`
  - `auth_login_success`
  - `auth_login_failed`
  - `api_request_failed`
  - `report_export_started`

### Theming + design tokens

- Use shared tokens from `core/theme/design_tokens.dart`.
- Never hard-code colors/spacing in feature widgets when token equivalent exists.

## Navigation contract

The module-level route paths are locked as:

- `/auth`
- `/dashboard`
- `/reports`
- `/settings`
