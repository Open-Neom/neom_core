# Changelog — neom_core

## [Unreleased] - Change-Approval support in AppRequest
- `RequestType` enum unified: adds semantic kinds (`collaboration`, `gameInvitation`, `dawInvitation`, `releaseApproval`, `changeApproval`) alongside mailbox values (`received`, `sent`, `invitation`).
- `AppRequest`: new persisted `type` field + generic `payload` map; getters (`isGameRequest`, `isReleaseApprovalRequest`, `isChangeApprovalRequest`, `isDawInvitation`) now evaluate the enum instead of parsing the id.
- `AppRequest.changeApproval(...)` factory (with `action` + `extra`) plus `changeAction` / `changeModule` helpers for generic, module-agnostic approval requests.
- `RequestFirestore.retrieveChangeApprovalRequests()` to fetch the pending change-approval queue.
- `ErpIntegrationService.finalizeSaleIncome(...)`: books a shop-sale income, credits the seller royalty wallet and notifies the seller once finance confirms payment; `ingestPaidOrder` now defers the income to this approval step.

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
