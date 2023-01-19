import 'package:enum_to_string/enum_to_string.dart';
import '../../data/api_services/push_notification/notification_channel_constants.dart';
import '../../utils/enums/push_notification_type.dart';

class PushNotificationMessage {

  String title = "";
  String body = "";
  String fromId = "";
  String fromName = "";
  String fromImgUrl = "";
  String referenceId = "";
  String? imgUrl = "";
  PushNotificationType type = PushNotificationType.message;
  int channelId = 0;
  String channelKey = "";

  PushNotificationMessage({
    required this.title,
    required this.body
  });


  @override
  String toString() {
    return 'PushNotificationMessage{title: $title, body: $body, fromId: $fromId, fromName: $fromName, fromImgUrl: $fromImgUrl, referenceId: $referenceId, imgUrl: $imgUrl, type: $type, channelId: $channelId, channelKey: $channelKey}';
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
        channelKey = data["channelKey"] ?? NotificationChannelConstants.message,
        channelId = int.parse(data["channelId"] ?? "4"),
        referenceId = data["referenceId"] ?? "";


}
