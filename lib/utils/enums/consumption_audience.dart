/// Who consumed a piece of content, as far as creator earnings are concerned.
///
/// Listening (CASETE) and reading (NUPALE) sessions are recorded for every
/// account that can persist activity — creators need to see all of their
/// audience — but only one audience funds royalties. Each audience has its
/// own collection, so a payout that reads the member collection cannot count
/// anyone else by mistake.
enum ConsumptionAudience {
  /// A paying member who owns no release item: the only audience whose time
  /// counts toward royalties.
  member,

  /// An account that owns at least one release item. Analytics only: an
  /// author listening to or reading anyone's work would add to the platform
  /// total and lower the value per second or page — their own earnings
  /// included.
  author,

  /// No paid tier: time-limited listening or reading. Analytics only.
  freeTier,
}
