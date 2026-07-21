
## [2.0.0-unreleased] - 2026-07-21
- Refactor and compatibility updates for app_properties.dart, app_firestore_collection_constants.dart, itemlist_firestore.dart, app_release_item.dart, item_list.dart and 6 more.
# Changelog — neom_core

## [2.1.1] - 2026-07-16
- Add email field to AppProfile for corporate search filtering.
- Add muteVideoPlayer() to MediaPlayerService interface.
- Support email deserialization from parent reference in ProfileFirestore.

## [1.1.0] - 2026-07-09
- Optimize core root page and JS helper stub/web bridge configurations.

## Unreleased - Dedicated support room (`{profileId}_support`)
- New `CoreConstants.appSupport = "support"` + `InboxFirestore.getOrCreateSupportRoom(profileId)` → a per-user **Customer Support** thread (`{profileId}_support`), separate from the appBot announcements room and **behaving like a normal 1:1 chat** (the user writes). Marked `Inbox.isSupportRoom = true` (backfilled) so the ERP lists **every** support room the moment it's created (`streamRecentSupportRooms` now queries `isSupportRoom == true`, client-sorted). Support messages are plaintext (multiple agents + Itzli read them).

## Unreleased - Inbox support handoff state (Itzli ↔ Atención al Cliente)
- `Inbox` gains customer-support handoff fields: `handlerMode` ('itzli'|'human'), `needsHuman`, `assignedSupportId`, `lastHumanAt`, `lastUserAt`.
- `InboxFirestore`: `setSupportHandoff(roomId, data)`, `streamSupportQueue()` / `getSupportQueue()` (threads needing a human, most-recently-active first). Builds on the existing per-user `getOrCreateAppBotRoom` thread so Itzli and human agents share one continuous conversation.

## [Unreleased] - Role-targeted request notifications
- `UserFirestore.getProfileIdsByMinRole(UserRole)` — returns current profile ids of users at or above a role, so request flows can notify the staff allowed to approve them.

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
