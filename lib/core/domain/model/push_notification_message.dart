import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/push_notification_type.dart';

class PushNotificationMessage {

  String title;
  String body;
  String fromId;
  String fromName;
  String fromImgUrl;
  String referenceId;
  String? imgUrl;
  PushNotificationType type;
  int channelId;
  String channelKey;

  String toId;
  bool isPublic;

  PushNotificationMessage({
    required this.title,
    required this.body,
    required this.fromId,
    this.fromName = '',
    this.fromImgUrl = '',
    this.referenceId = '',
    this.imgUrl,
    this.type = PushNotificationType.message,
    this.channelId = 0,
    this.channelKey = "",
    this.toId = '',
    this.isPublic = false,
  });


  @override
  String toString() {
    return 'PushNotificationMessage{title: $title, body: $body, fromId: $fromId, fromName: $fromName, fromImgUrl: $fromImgUrl, imgUrl: $imgUrl, type: ${type.name}, channelKey: $channelKey, channelId: $channelId, referenceId: $referenceId, toId: $toId, isPublic: $isPublic}';
  }


  PushNotificationMessage.fromMessageData(data) :
    title = data["title"] ?? "",
    body = data["body"] ?? "",
    fromId = data["fromId"] ?? "",
    fromName = data["fromName"] ?? "",
    fromImgUrl = data["fromImgUrl"] ?? "",
    imgUrl = data["imgUrl"] ?? "",
    type = EnumToString.fromString(PushNotificationType.values, data["notificationType"]
        ?? PushNotificationType.message.name) ??  PushNotificationType.message,
    channelKey = data["channelKey"] ?? PushNotificationType.message.name,
    channelId = int.parse(data["channelId"] ?? PushNotificationType.message.value.toString()),
    referenceId = data["referenceId"] ?? "",
    toId = data["toId"] ?? "",
    isPublic = (data["isPublic"]?.toString().toLowerCase() == 'true');



}
