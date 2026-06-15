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
  /// `{ 'question': String, 'options': [String], 'votes': { '0': [profileIds] } }`.
  Map<String, dynamic>? pollData;

  /// Track the transmission medium over which this message was received ('ble', 'wifi', 'data')
  String receivedMedia;

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
  });

  /// Total reactions across all emojis.
  int get reactionCount => reactions.values.fold(0, (s, l) => s + l.length);

  @override
  String toString() {
    return 'InboxMessage{id: $id, ownerId: $ownerId, profileName: $profileName, profileImgUrl: $profileImgUrl, text: $text, createdTime: $createdTime, seenTime: $seenTime, type: $type, mediaUrl: $mediaUrl, referenceId: $referenceId, audioDuration: $audioDuration, likedProfiles: $likedProfiles, isPinned: $isPinned, pollId: $pollId, receivedMedia: $receivedMedia}';
  }

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
    };
  }

  InboxMessage.fromJSON(dynamic data) :
    id = data['id'] ?? "",
    ownerId = data['ownerId'] ?? "",
    profileName = data["profileName"] ?? "",
    profileImgUrl = data["profileImgUrl"] ?? "",
    text = data["text"] ?? "",
    createdTime = data["createdTime"] ?? 0,
    seenTime = data["seenTime"] ?? 0,
    type = data["type"] != null
        ? (EnumToString.fromString(AppMediaType.values, data["type"]) ?? AppMediaType.text)
        : AppMediaType.text,
    mediaUrl = data["mediaUrl"] ?? "",
    referenceId = data["referenceId"] ?? "",
    audioDuration = data["audioDuration"] ?? 0,
    likedProfiles = List<String>.from(data["likedProfiles"] ?? []),
    isPinned = data["isPinned"] ?? false,
    pollId = data["pollId"] ?? "",
    reactions = ((data["reactions"] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), List<String>.from(v ?? []))) ?? {})
        .cast<String, List<String>>(),
    threadParentId = data["threadParentId"] ?? "",
    replyCount = data["replyCount"] ?? 0,
    pollData = (data["pollData"] as Map?)?.map((k, v) => MapEntry(k.toString(), v))?.cast<String, dynamic>(),
    receivedMedia = data['receivedMedia'] ?? "";
}
