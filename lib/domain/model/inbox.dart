
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

  // List<AppProfile>? profiles;
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
  });


  @override
  String toString() {
    return 'Inbox{id: $id, isPrivate: $isPrivate, lastMessage: $lastMessage, createdTime: $createdTime, profileIds: $profileIds, messages: $messages}';
  }


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
    };
  }

  Inbox.fromJSON(dynamic data) :
        id = data["id"] ?? "",
        isPrivate = data["isPrivate"] ?? true,
        profileIds = List.from(data["profileIds"] ?? []),
        lastMessage = data["lastMessage"] == null ? InboxMessage()
            : InboxMessage.fromJSON(data["lastMessage"] ?? <dynamic, dynamic>{}),
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
        summaryEmailedAt = data["summaryEmailedAt"] ?? 0;

  ///DEPRECATED
  // Inbox.fromDocumentSnapshot(DocumentSnapshot documentSnapshot):
  //   id = documentSnapshot.id,
  //   isPrivate = documentSnapshot.get("isPrivate") ?? true,
  //   profileIds = List.from(documentSnapshot.get("profileIds") ?? []),
  //   lastMessage = documentSnapshot.get("lastMessage") == null ? InboxMessage()
  //       : InboxMessage.fromJSON(documentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
  //   createdTime = documentSnapshot.get("createdTime") ?? 0;

  ///DEPRECATED
  // Inbox.fromQueryDocumentSnapshot(QueryDocumentSnapshot queryDocumentSnapshot):
  //   id = queryDocumentSnapshot.id,
  //   isPrivate = queryDocumentSnapshot.get("isPrivate") ?? true,
  //   profileIds = List.from(queryDocumentSnapshot.get("profileIds") ?? []),
  //   lastMessage = queryDocumentSnapshot.get("lastMessage") == null ? InboxMessage()
  //       : InboxMessage.fromJSON(queryDocumentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
  //   createdTime = queryDocumentSnapshot.get("createdTime") ?? 0;



}
