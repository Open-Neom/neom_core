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
    this.likedProfiles = const []
  });

  @override
  String toString() {
    return 'InboxMessage{id: $id, ownerId: $ownerId, profileName: $profileName, profileImgUrl: $profileImgUrl, text: $text, createdTime: $createdTime, seenTime: $seenTime, type: $type, mediaUrl: $mediaUrl, referenceId: $referenceId, audioDuration: $audioDuration, likedProfiles: $likedProfiles}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id,
      'ownerId': ownerId,
      'profileName': profileName,
      'profileImgUrl': profileImgUrl,
      'text': text,
      'createdTime': DateTime.now().millisecondsSinceEpoch,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'referenceId': referenceId,
      'audioDuration': audioDuration,
      'likedProfiles': likedProfiles
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
    type = EnumToString.fromString(AppMediaType.values, data["type"]) ?? AppMediaType.text,
    mediaUrl = data["mediaUrl"] ?? "",
    referenceId = data["referenceId"] ?? "",
    audioDuration = data["audioDuration"] ?? 0,
    likedProfiles = List.from(data["likedProfiles"] ?? []);

}
