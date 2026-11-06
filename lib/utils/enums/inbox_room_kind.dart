/// Standard room classification across all Open Neom applications.
///
/// Covers 1:1 chats, multi-member groups, proximity/distance mesh channels,
/// collectives, communities, customer support, internal team rooms, and bots.
enum InboxRoomKind {
  direct,
  group,
  nearbyZone,
  collective,
  community,
  support,
  team,
  bot;

  static InboxRoomKind fromString(String? raw) {
    if (raw == null || raw.isEmpty) return InboxRoomKind.direct;
    for (final kind in InboxRoomKind.values) {
      if (kind.name == raw) return kind;
    }
    return InboxRoomKind.direct;
  }
}
