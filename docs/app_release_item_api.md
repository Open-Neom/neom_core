# AppReleaseItemApi: configurable data-server migration

`AppReleaseItemRepository` is unchanged. `AppReleaseItemApi` implements the
existing contract; `AppReleaseItemFirestore` remains the working cloud adapter.
The default for hosts without registration or explicit configuration is still
Firestore. No Firebase deployments, rule changes, or database migrations are
performed by this change.

## Host configuration

Gigmeout and Itzli register `AppReleaseItems.create` against the existing
repository interface in RootBinding. They use separate `dataBackend` settings
in their own properties.json. AppInUse.g and AppInUse.i are eligible; EMXI and
all other AppInUse values remain on Firestore even if this property is copied.
Firebase demo projects also keep Firestore/emulator isolation.

```json
{
  "dataBackend": {
    "enabled": true,
    "baseUrl": "https://your-data-server.example",
    "firebaseFallback": true,
    "syncEnabled": true,
    "timeoutMs": 4000
  }
}
```

Gigmeout now uses `same-origin` only for its explicitly allowed loopback origins
on port 8787. Itzli keeps an empty URL. Firebase-hosted web and native clients
without an explicit compatible URL retain Firestore. The local server is
implemented under `Gigmeout/server`; public HTTPS access remains unconfigured. An enabled but unconfigured
adapter reads Firebase and records reconciliation requests. Gigmeout awaits
property initialization before constructing its bindings. Production endpoints
should use HTTPS; plain HTTP remains available for controlled LAN development.

Use `AppReleaseItems.repository` or inject `AppReleaseItemRepository` into
consumers. Catalog reads in Timeline, audio home/search/recommendations,
shared search, common deep links and profile slug lookups now use the contract.
The release uploader uses the injected insert implementation and preserves the
legacy Firestore generated-ID behavior for hosts still using that adapter.

Firestore-specific operations outside this contract (ownership queries,
moderation, owner+slug lookups, view counters, deduplication, and legacy playlist
hydration) still use their existing implementation. Their migration is separate.
User/Auth repositories, file uploads, payments, and storage URLs are unchanged.
The accompanying `Gigmeout/server` implementation now runs the compatible
local API using SQLite; this does not migrate file Storage or other modules.

## Read protocol

`GET {baseUrl}/v1/apps/{appLetter}/releases`

- Accept: application/json. A current Firebase ID token is sent when available;
  the server must verify it and independently enforce authorization.
- `audience=public` for Gigmeout's current public-catalog policy;
  `audience=account` otherwise. This parameter is not proof of authorization.
- Filters: `ids` (JSON string array), `slug`, `category`, `ownerEmail`, `language`,
  `limit`, `forceRefresh`. IDs must be exact and the backend must validate filters.
- Response: `{ "items": [ ... ], "nextCursor": "optional-opaque-cursor" }`.
  Items use AppReleaseItem.toJSON shape with stable string IDs. Return the whole
  matching catalog or paginated results; cursors must retain a consistent query
  snapshot. Repeated/invalid cursors are rejected. Filter limits apply overall.
- Public items additionally require `visibility: "public"`, `schemaVersion: 1`,
  published status and no suspension. Account-only fields are stripped by the
  existing public projection method. Owner-email queries remain disabled publicly.
- An empty successful result is authoritative, never a reason to resurrect cloud
  content. Transport errors, timeouts and 502/503/504 allow configured cloud
  fallback. 401/403/404 and other application errors do not trigger fallback.
- Firebase fallback retains existing Firestore query/cache/error semantics.
  This adapter does not replace the host's existing Hive catalog cache.

## Pending operations and server acknowledgement

`POST {baseUrl}/v1/apps/{appLetter}/releases/operations`

Header `Idempotency-Key` equals the stable `operationId` in the body. The server
must enforce idempotency, authorization and durable application before returning
`{ "acknowledgedOperationId": "the-same-id" }`. Merely enqueueing a server job
must not acknowledge final reconciliation unless the server durably owns its
retry and failure handling. Client-generated actor or ownership fields are not
authority. A single-node server must still make receipts survive restarts.

Kinds:

- `upsert`: payload.item contains the release; an ID is assigned before sending.
- `remove`: payload.releaseId; server must implement versioned tombstones.
- `addBoughtUser`: payload.releaseId and payload.userId; server must independently
  verify purchase/permission rather than accepting a client purchase assertion.
- `reconcileFirestore`: releaseId and audience, references only, no trusted
  client snapshot. The server reads the authorized Firestore source, preserves
  IDs, checks versions and reconciles without overwriting newer local changes.
- `reconcileFirestoreCatalog`: scheduled on first catalog load per actor and on
  forced refresh. The server owns incremental cloud checkpoints, deduplication,
  deletion discovery, conflict handling and rate limiting. A client must not be
  able to initiate unbounded privileged cloud scans.

Mutation jobs are persisted before sending. Network loss and transient write
errors keep the job and throw `ReleaseWritePending(operationId)`, including when
the server might already have committed. Replays reuse the same key. Definitive
4xx rejection (except 408/429) is not automatically retried. Do not treat a
pending exception as completed publication. There is no automatic second write
to Firestore: it cannot safely participate in an ambiguous cross-backend retry.

## Queue lifetime and scope

Hive outboxes are separated by app letter and Firebase UID (guest uses an empty
actor), survive restarts, and never persist access tokens. Session changes reject
in-flight results and prevent replay as another user. Read-fallback reconciliation
jobs contain references only. Writes require a loaded authenticated session.
Outbox files still contain private mutation data and should follow account-data
retention policy on logout/account deletion.

Pending jobs flush after a successful API read, or explicitly by calling
`flushPending()` on the bound AppReleaseItemApi. There is no unattended background
server process: the app must run, and the data endpoint must implement the above
protocol. Acknowledgements remove only their matching operation revision;
concurrent replacement of a reconciliation job is preserved. Failed sync remains
queued and is exposed through `lastSyncError`. Read fallback is still usable if
recording a reconciliation request fails; that failure is also exposed there.

The backup has now been imported into the separate SQLite database used by
`Gigmeout/server`. Its authorized read-only cloud reconciliation preserves local
edits. It does not mirror local writes back to Firebase or provide automatic
resolution of all conflicts; see the server README for the operational limits.

## Validation

The adapter tests cover per-app eligibility, independent endpoint configuration,
transport fallback, authoritative absence, denied reads, public projection,
stable mutation IDs, durable acknowledgements, failed writes, account isolation,
Hive reopening and pagination. Existing cache/model and host session/routing
tests are also run. No tests contact or modify production Firebase.
