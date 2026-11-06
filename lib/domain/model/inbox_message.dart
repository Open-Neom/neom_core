import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_media_type.dart';

class InboxMessage {
  String id;
  String ownerId;
  String profileName;
  String profileImgUrl;

  String text;
  int createdTime;
  int seenTime;

  AppMediaType type;
  String mediaUrl;
  String referenceId;
  int audioDuration; // Duration in milliseconds for voice messages

  List<String> likedProfiles;

  bool isPinned;
  String pollId;

  /// Multi-emoji reactions: emoji → list of profileIds who reacted with it.
  Map<String, List<String>> reactions;

  /// If set, this message is a reply inside the thread of message [threadParentId]
  /// — it lives in the message thread, not the main timeline.
  String threadParentId;

  /// Number of thread replies under this (parent) message.
  int replyCount;

  /// Inline poll payload when [type] == AppMediaType.poll:
  /// `{ 'question': String, 'options': [String], 'votes': { '0': [profileIds] }, 'allowMultiple': bool }`.
  Map<String, dynamic>? pollData;

  /// Track the transmission medium over which this message was received ('ble', 'wifi', 'swarm', 'data')
  String receivedMedia;

  // ── Open Neom Standard Rich Messaging Extensions ────────────────────────

  /// Quoted reply snapshot for WhatsApp-style swipe-to-reply:
  /// `{ 'id': String, 'ownerId': String, 'senderName': String, 'text': String, 'type': String }`.
  Map<String, dynamic>? replyData;

  /// Inline location payload when [type] == AppMediaType.location:
  /// `{ 'lat': double, 'lng': double, 'label': String, 'address': String, 'isLive': bool, 'liveUntilMs': int }`.
  Map<String, dynamic>? locationData;

  /// Document attachment metadata when [type] == AppMediaType.document:
  /// `{ 'fileName': String, 'mimeType': String, 'sizeBytes': int, 'pageCount': int? }`.
  Map<String, dynamic>? documentData;

  /// Contact card / BLE peer identity payload when [type] == AppMediaType.contact:
  /// `{ 'id': String, 'name': String, 'subtitle': String, 'photoUrl': String, 'bleCard': String? }`.
  Map<String, dynamic>? contactData;

  /// Local file path for instant offline / Bluetooth / Wi-Fi Direct rendering
  /// without waiting for or requiring cloud upload.
  String localFilePath;

  /// Delivery lifecycle status ('sending', 'queued_mesh', 'sent', 'delivered', 'seen', 'error').
  String deliveryStatus;

  /// Timestamp (ms) when the recipient or mesh relay acknowledged delivery.
  int deliveredTime;

  /// Timestamp (ms) when the sender edited the message text (`0` if unedited).
  int editedTime;

  /// Tombstone marker when the sender chooses "Eliminar para todos".
  bool isDeletedForEveryone;

  /// Profile IDs for whom this message was hidden via "Eliminar para mí".
  List<String> hiddenForProfileIds;

  /// Whether this message was forwarded from another chat.
  bool isForwarded;

  /// Profile IDs who starred/highlighted this message (`⭐`).
  List<String> starredByProfileIds;

  /// Mesh hop count (`0` for cloud, `>= 1` for BLE/Wi-Fi/Río Colmena relays).
  int hopCount;

  /// Approximate proximity distance in meters when received on a nearby channel.
  double? distanceMeters;

  InboxMessage({
    this.id = "",
    this.ownerId = "",
    this.profileName = "",
    this.profileImgUrl = "",
    this.text = "",
    this.createdTime = 0,
    this.seenTime = 0,
    this.type = AppMediaType.text,
    this.mediaUrl = "",
    this.referenceId = "",
    this.audioDuration = 0,
    this.likedProfiles = const [],
    this.isPinned = false,
    this.pollId = "",
    this.reactions = const {},
    this.threadParentId = "",
    this.replyCount = 0,
    this.pollData,
    this.receivedMedia = "",
    this.replyData,
    this.locationData,
    this.documentData,
    this.contactData,
    this.localFilePath = "",
    this.deliveryStatus = "",
    this.deliveredTime = 0,
    this.editedTime = 0,
    this.isDeletedForEveryone = false,
    this.hiddenForProfileIds = const [],
    this.isForwarded = false,
    this.starredByProfileIds = const [],
    this.hopCount = 0,
    this.distanceMeters,
  });

  /// Total reactions across all emojis.
  int get reactionCount => reactions.values.fold(0, (s, l) => s + l.length);

  /// Whether this message carries a visible swipe-to-reply quote.
  bool get hasReply => replyData != null && replyData!.isNotEmpty;

  /// Effective media URL or local file path for offline/mesh playback & preview.
  String get effectiveMediaSource =>
      localFilePath.isNotEmpty ? localFilePath : mediaUrl;

  /// Whether this message is hidden for [profileId] ("Eliminar para mí").
  bool isHiddenFor(String profileId) =>
      profileId.isNotEmpty && hiddenForProfileIds.contains(profileId);

  /// Whether [profileId] starred this message.
  bool isStarredBy(String profileId) =>
      profileId.isNotEmpty && starredByProfileIds.contains(profileId);

  @override
  String toString() {
    return 'InboxMessage{id: $id, ownerId: $ownerId, profileName: $profileName, profileImgUrl: $profileImgUrl, text: $text, createdTime: $createdTime, seenTime: $seenTime, type: $type, mediaUrl: $mediaUrl, referenceId: $referenceId, audioDuration: $audioDuration, likedProfiles: $likedProfiles, isPinned: $isPinned, pollId: $pollId, receivedMedia: $receivedMedia}';
  }

  Map<String, dynamic> toJson() => toJSON();

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id,
      'ownerId': ownerId,
      'profileName': profileName,
      'profileImgUrl': profileImgUrl,
      'text': text,
      'createdTime': createdTime,
      'seenTime': seenTime,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'referenceId': referenceId,
      'audioDuration': audioDuration,
      'likedProfiles': likedProfiles,
      'isPinned': isPinned,
      'pollId': pollId,
      'reactions': reactions,
      'threadParentId': threadParentId,
      'replyCount': replyCount,
      'pollData': pollData,
      'receivedMedia': receivedMedia,
      if (replyData != null) 'replyData': replyData,
      if (locationData != null) 'locationData': locationData,
      if (documentData != null) 'documentData': documentData,
      if (contactData != null) 'contactData': contactData,
      if (localFilePath.isNotEmpty) 'localFilePath': localFilePath,
      if (deliveryStatus.isNotEmpty) 'deliveryStatus': deliveryStatus,
      if (deliveredTime > 0) 'deliveredTime': deliveredTime,
      if (editedTime > 0) 'editedTime': editedTime,
      if (isDeletedForEveryone) 'isDeletedForEveryone': isDeletedForEveryone,
      if (hiddenForProfileIds.isNotEmpty)
        'hiddenForProfileIds': hiddenForProfileIds,
      if (isForwarded) 'isForwarded': isForwarded,
      if (starredByProfileIds.isNotEmpty)
        'starredByProfileIds': starredByProfileIds,
      if (hopCount > 0) 'hopCount': hopCount,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
    };
  }

  static Map<String, dynamic>? _asStringMap(dynamic raw) {
    if (raw is! Map) return null;
    return raw.map((k, v) => MapEntry(k.toString(), v)).cast<String, dynamic>();
  }

  InboxMessage.fromJSON(dynamic data)
      : id = data['id'] ?? "",
        ownerId = data['ownerId'] ?? "",
        profileName = data["profileName"] ?? "",
        profileImgUrl = data["profileImgUrl"] ?? "",
        text = data["text"] ?? "",
        createdTime = data["createdTime"] ?? 0,
        seenTime = data["seenTime"] ?? 0,
        type = data["type"] != null
            ? (EnumToString.fromString(AppMediaType.values, data["type"]) ??
                AppMediaType.text)
            : AppMediaType.text,
        mediaUrl = data["mediaUrl"] ?? "",
        referenceId = data["referenceId"] ?? "",
        audioDuration = data["audioDuration"] ?? 0,
        likedProfiles = List<String>.from(data["likedProfiles"] ?? []),
        isPinned = data["isPinned"] ?? false,
        pollId = data["pollId"] ?? "",
        reactions = ((data["reactions"] as Map?)?.map((k, v) =>
                    MapEntry(k.toString(), List<String>.from(v ?? []))) ??
                {})
            .cast<String, List<String>>(),
        threadParentId = data["threadParentId"] ?? "",
        replyCount = data["replyCount"] ?? 0,
        pollData = _asStringMap(data["pollData"]),
        receivedMedia = data['receivedMedia'] ?? "",
        replyData = _asStringMap(data["replyData"]),
        locationData = _asStringMap(data["locationData"]),
        documentData = _asStringMap(data["documentData"]),
        contactData = _asStringMap(data["contactData"]),
        localFilePath = data["localFilePath"] ?? "",
        deliveryStatus = data["deliveryStatus"] ?? "",
        deliveredTime = data["deliveredTime"] ?? 0,
        editedTime = data["editedTime"] ?? 0,
        isDeletedForEveryone = data["isDeletedForEveryone"] ?? false,
        hiddenForProfileIds =
            List<String>.from(data["hiddenForProfileIds"] ?? []),
        isForwarded = data["isForwarded"] ?? false,
        starredByProfileIds =
            List<String>.from(data["starredByProfileIds"] ?? []),
        hopCount = data["hopCount"] ?? 0,
        distanceMeters = (data["distanceMeters"] as num?)?.toDouble();
}
