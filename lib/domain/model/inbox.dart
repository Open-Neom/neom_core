import '../../utils/enums/inbox_room_kind.dart';
import 'inbox_message.dart';

class Inbox {
  String id;
  bool isPrivate;
  InboxMessage? lastMessage;
  int createdTime;
  List<String> profileIds;

  // ── Customer-support handoff (appBot rooms: Itzli ↔ human agent) ──
  /// Who is currently driving the conversation: 'itzli' (AI first responder)
  /// or 'human' (a Customer Support agent took over).
  String handlerMode;

  /// True when Itzli couldn't resolve and a human agent is needed → the thread
  /// surfaces in the Atención al Cliente queue.
  bool needsHuman;

  /// Profile id of the support agent handling this thread (when human).
  String assignedSupportId;

  /// Last time a human agent posted (so Itzli knows the latest human context).
  int lastHumanAt;

  /// Last time the end user wrote (queue ordering / SLA).
  int lastUserAt;

  /// True for Customer Support threads (`{profileId}_support`) so the ERP can
  /// list every support room the moment it's created.
  bool isSupportRoom;

  /// True for the shared internal team channel (`team_room`).
  bool isTeamRoom;

  /// Customer satisfaction score (1–5) the user gave after a human session.
  /// 0 = not rated.
  int csatScore;

  /// When the CSAT score was submitted (ms).
  int csatAt;

  /// Itzli-classified support topic (cobros/cupones/reproduccion/cuenta/otro)
  /// used for the A&S topic-distribution chart and the self-training KB.
  String supportTopic;

  /// Last time an AI "unresolved summary" email was sent to the user (ms) — guards
  /// against re-emailing when the user reopens/closes the room without new activity.
  int summaryEmailedAt;

  // ── Open Neom Standard Group & Proximity Room Extensions ───────────────
  /// Room classification across Open Neom apps (direct, group, nearbyZone, etc.).
  InboxRoomKind roomKind;

  /// Display title for groups, nearby distance channels, collectives, or communities.
  String name;

  /// Avatar URL for groups or channels.
  String photoUrl;

  /// Group description, neighborhood distance label, or channel subtitle.
  String description;

  /// Profile IDs with administrator permissions in group rooms.
  List<String> adminIds;

  /// Profile IDs who pinned this conversation to the top of their inbox.
  List<String> pinnedByProfileIds;

  /// Profile IDs who muted notifications for this room.
  List<String> mutedByProfileIds;

  /// Active transport policy ('cloud', 'mesh', 'hybrid').
  String transportMode;

  /// Symmetric group key identifier (`GroupEpochKey`) for offline/BLE groups.
  String groupKeyId;

  /// Geohash / spatial zone code for distance/proximity channels.
  String geohashZone;

  List<InboxMessage>? messages;

  Inbox({
    this.id = "",
    this.isPrivate = true,
    this.profileIds = const [],
    this.lastMessage,
    this.createdTime = 0,
    this.handlerMode = 'itzli',
    this.needsHuman = false,
    this.assignedSupportId = '',
    this.lastHumanAt = 0,
    this.lastUserAt = 0,
    this.isSupportRoom = false,
    this.isTeamRoom = false,
    this.csatScore = 0,
    this.csatAt = 0,
    this.supportTopic = '',
    this.summaryEmailedAt = 0,
    InboxRoomKind? roomKind,
    this.name = '',
    this.photoUrl = '',
    this.description = '',
    this.adminIds = const [],
    this.pinnedByProfileIds = const [],
    this.mutedByProfileIds = const [],
    this.transportMode = 'cloud',
    this.groupKeyId = '',
    this.geohashZone = '',
  }) : roomKind = roomKind ??
            _inferKind(
              rawKind: null,
              isSupportRoom: isSupportRoom,
              isTeamRoom: isTeamRoom,
              profileIds: profileIds,
              id: id,
            );

  static InboxRoomKind _inferKind({
    required String? rawKind,
    required bool isSupportRoom,
    required bool isTeamRoom,
    required List<String> profileIds,
    required String id,
  }) {
    if (rawKind != null && rawKind.isNotEmpty) {
      return InboxRoomKind.fromString(rawKind);
    }
    if (isSupportRoom || id.endsWith('_support')) return InboxRoomKind.support;
    if (isTeamRoom || id == 'team_room') return InboxRoomKind.team;
    if (id.contains('appBot')) return InboxRoomKind.bot;
    if (id.startsWith('nearby_') || id.startsWith('blup_nearby')) {
      return InboxRoomKind.nearbyZone;
    }
    if (id.startsWith('group_') || profileIds.length > 2) {
      return InboxRoomKind.group;
    }
    return InboxRoomKind.direct;
  }

  /// True when this room represents a multi-participant group, team, collective, or community.
  bool get isGroup =>
      roomKind == InboxRoomKind.group ||
      roomKind == InboxRoomKind.collective ||
      roomKind == InboxRoomKind.community ||
      roomKind == InboxRoomKind.team ||
      isTeamRoom;

  /// True when this room is a proximity / distance mesh channel.
  bool get isNearbyChannel => roomKind == InboxRoomKind.nearbyZone;

  /// True when this room uses BLE / Wi-Fi / Río Colmena mesh transport.
  bool get isMeshBacked =>
      transportMode == 'mesh' || transportMode == 'hybrid' || isNearbyChannel;

  bool isPinnedBy(String profileId) =>
      profileId.isNotEmpty && pinnedByProfileIds.contains(profileId);

  bool isMutedBy(String profileId) =>
      profileId.isNotEmpty && mutedByProfileIds.contains(profileId);

  @override
  String toString() {
    return 'Inbox{id: $id, kind: ${roomKind.name}, name: $name, isPrivate: $isPrivate, lastMessage: $lastMessage, createdTime: $createdTime, profileIds: $profileIds, messages: $messages}';
  }

  Map<String, dynamic> toJson() => toJSON();

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'isPrivate': isPrivate,
      'lastMessage': lastMessage?.toJSON(),
      'profileIds': profileIds,
      'createdTime': createdTime,
      'handlerMode': handlerMode,
      'needsHuman': needsHuman,
      'assignedSupportId': assignedSupportId,
      'lastHumanAt': lastHumanAt,
      'lastUserAt': lastUserAt,
      'isSupportRoom': isSupportRoom,
      'isTeamRoom': isTeamRoom,
      'csatScore': csatScore,
      'csatAt': csatAt,
      'supportTopic': supportTopic,
      'summaryEmailedAt': summaryEmailedAt,
      if (roomKind != InboxRoomKind.direct) 'roomKind': roomKind.name,
      if (name.isNotEmpty) 'name': name,
      if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      if (description.isNotEmpty) 'description': description,
      if (adminIds.isNotEmpty) 'adminIds': adminIds,
      if (pinnedByProfileIds.isNotEmpty)
        'pinnedByProfileIds': pinnedByProfileIds,
      if (mutedByProfileIds.isNotEmpty) 'mutedByProfileIds': mutedByProfileIds,
      if (transportMode != 'cloud') 'transportMode': transportMode,
      if (groupKeyId.isNotEmpty) 'groupKeyId': groupKeyId,
      if (geohashZone.isNotEmpty) 'geohashZone': geohashZone,
    };
  }

  Inbox.fromJSON(dynamic data)
      : id = data["id"] ?? "",
        isPrivate = data["isPrivate"] ?? true,
        profileIds = List<String>.from(data["profileIds"] ?? []),
        lastMessage = data["lastMessage"] == null
            ? InboxMessage()
            : InboxMessage.fromJSON(
                data["lastMessage"] ?? <dynamic, dynamic>{}),
        createdTime = data["createdTime"] ?? 0,
        handlerMode = data["handlerMode"] ?? 'itzli',
        needsHuman = data["needsHuman"] ?? false,
        assignedSupportId = data["assignedSupportId"] ?? '',
        lastHumanAt = data["lastHumanAt"] ?? 0,
        lastUserAt = data["lastUserAt"] ?? 0,
        isSupportRoom = data["isSupportRoom"] ?? false,
        isTeamRoom = data["isTeamRoom"] ?? false,
        csatScore = data["csatScore"] ?? 0,
        csatAt = data["csatAt"] ?? 0,
        supportTopic = data["supportTopic"] ?? '',
        summaryEmailedAt = data["summaryEmailedAt"] ?? 0,
        roomKind = _inferKind(
          rawKind: data["roomKind"] as String?,
          isSupportRoom: data["isSupportRoom"] ?? false,
          isTeamRoom: data["isTeamRoom"] ?? false,
          profileIds: List<String>.from(data["profileIds"] ?? []),
          id: data["id"] ?? "",
        ),
        name = data["name"] ?? '',
        photoUrl = data["photoUrl"] ?? '',
        description = data["description"] ?? '',
        adminIds = List<String>.from(data["adminIds"] ?? []),
        pinnedByProfileIds =
            List<String>.from(data["pinnedByProfileIds"] ?? []),
        mutedByProfileIds = List<String>.from(data["mutedByProfileIds"] ?? []),
        transportMode = data["transportMode"] ?? 'cloud',
        groupKeyId = data["groupKeyId"] ?? '',
        geohashZone = data["geohashZone"] ?? '';
}
