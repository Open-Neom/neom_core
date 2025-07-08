import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/app_media_type.dart';

class CommentReply {

  String id;
  String text;
  int likeCount;
  AppMediaType? mediaType;
  bool isHidden;
  String profileId;
  int createdTime;
  int modifiedTime;

  CommentReply({
    this.id = "",
    this.profileId = "",
    this.text = "",
    this.likeCount = 0,
    this.mediaType,
    this.isHidden = false,
    this.createdTime = 0,
    this.modifiedTime = 0
  });


  @override
  String toString() {
    return 'CommentReply{id: $id, text: $text, likeCount: $likeCount, mediaType: $mediaType, isHidden: $isHidden, profileId: $profileId, createdTime: $createdTime, modifiedTime: $modifiedTime}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'likeCount': likeCount,
      'mediaType': mediaType?.name ?? "",
      'isHidden': isHidden,
      'profileId': profileId,
      'createdTime': createdTime,
      'modifiedTime': modifiedTime,
    };
  }

  CommentReply.fromJSON(Map<dynamic, dynamic> data) :
    id = data["id"],
    text = data["text"],
    likeCount = data["likeCount"],
    mediaType = EnumToString.fromString(AppMediaType.values, data["mediaType"]),
    isHidden = data["isHidden"],
    profileId = data["profileId"],
    createdTime = data["createdTime"],
    modifiedTime = data["modifiedTime"];

}
