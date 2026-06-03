/// Unified request enum.
///
/// Combines two orthogonal concerns intentionally kept in a single enum to
/// avoid proliferating types:
///
/// 1. **Mailbox / direction** — where a request lives on a profile
///    ([received], [sent], [invitation]). Used by ProfileFirestore.
/// 2. **Semantic kind** — what the request *is* ([collaboration],
///    [gameInvitation], [dawInvitation], [releaseApproval], [changeApproval]).
///    Stored on `AppRequest.type` so consumers evaluate the enum directly
///    instead of pattern-matching the request id (`_release_`, `_daw_`, ...).
enum RequestType {
  // ── Mailbox / direction ──
  received,
  sent,
  invitation,

  // ── Semantic kind ──
  /// General event/collective collaboration request (default).
  collaboration,
  /// Multiplayer game invitation.
  gameInvitation,
  /// DAW project collaboration invitation.
  dawInvitation,
  /// New publication awaiting moderator approval.
  releaseApproval,
  /// Edit / sensitive-data change awaiting moderator approval.
  changeApproval,
}

extension RequestTypeExtension on RequestType {
  /// Whether this value represents a mailbox/direction (vs a semantic kind).
  bool get isMailbox =>
      this == RequestType.received ||
      this == RequestType.sent ||
      this == RequestType.invitation;

  /// Whether this value represents an approval-gated request kind.
  bool get isApproval =>
      this == RequestType.releaseApproval || this == RequestType.changeApproval;
}
