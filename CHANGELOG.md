# Changelog — neom_core

## [2.0.0] - 2026-04-16
- Stable 2.0.0 release of neom_core.
- Add `createEventBands` route to AppRouteConstants.
- Add `noCollectivematesWereFound`, `loadingPossibleCollectivemates` to CommonTranslationConstants.

## [1.5.0] - 2026-03-14
- Add `isActive` getter to `MiniPlayerService` interface.
- Add `hubBenchmark` route constant.
- Add `hubBenchmarks` Firestore collection constant.
- Add fail-fast auth guard in `callSecureOps` (web) — throws early if user not logged in.
- Add `SaiaAdminService` interface and SAIA domain models.
- Add `SettingsService` language/theme methods.
