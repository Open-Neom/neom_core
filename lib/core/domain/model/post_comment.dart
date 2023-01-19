import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/app_media_type.dart';
import 'comment_reply.dart';

class PostComment {

  String id = "";
  String postOwnerId;
  String text;
  List<String> likedProfiles;
  AppMediaType type;
  List<CommentReply> replies;
  bool isHidden;
  String profileId;
  String profileImgUrl;
  String profileName;
  String mediaUrl;
  int createdTime;
  int modifiedTime;
  String postId;

  PostComment({
      this.id = "",
      required this.postOwnerId,
      required this.text,
      required this.postId,
      this.likedProfiles = const [],
      this.type = AppMediaType.text,
      this.replies = const [],
      this.isHidden = false,
      required this.profileId,
      required this.profileImgUrl,
      required this.profileName,
      this.mediaUrl = "",
      required this.createdTime,
      this.modifiedTime = 0,
  });

  @override
  String toString() {
    return 'PostComment{id: $id, postOwnerId: $postOwnerId, text: $text, likedProfiles: $likedProfiles, type: $type, replies: $replies, isHidden: $isHidden, profileId: $profileId, profileImgUrl: $profileImgUrl, profileName: $profileName, mediaUrl: $mediaUrl, createdTime: $createdTime, modifiedTime: $modifiedTime, postId: $postId}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'likedProfiles': likedProfiles,
      'type': type.name,
      'isHidden': isHidden,
      'profileId': profileId,
      'profileImgUrl': profileImgUrl,
      'profileName': profileName,
      'postOwnerId': postOwnerId,
      'mediaUrl': mediaUrl,
      'createdTime': createdTime,
      'modifiedTime': modifiedTime,
      'replies': replies,
      'postId': postId
    };
  }

  PostComment.fromJSON(data):
        text = data["text"] ?? "",
        likedProfiles = List.from(data["likedProfiles"] ?? []),
        type = EnumToString.fromString(AppMediaType.values, data["type"]) ?? AppMediaType.text,
        isHidden = data["isHidden"] ?? false,
        profileId = data["profileId"] ?? "",
        profileImgUrl = data["profileImgUrl"],
        profileName = data["profileName"],
        postOwnerId = data["postOwnerId"],
        mediaUrl = data["mediaUrl"],
        createdTime = data["createdTime"],
        modifiedTime = data["modifiedTime"],
        replies = data["replies"].map<CommentReply>((item) {
          return CommentReply.fromJSON(item);
        }).toList(),
        postId = data["postId"] ?? "";

}
