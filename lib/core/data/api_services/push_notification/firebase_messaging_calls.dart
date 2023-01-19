import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../domain/model/app_profile.dart';
import '../../../utils/app_utilities.dart';
import '../../../utils/constants/app_translation_constants.dart';
import '../../../utils/enums/push_notification_type.dart';
import '../../firestore/profile_firestore.dart';
import 'notification_channel_constants.dart';
import 'push_notification_config.dart';

Future<http.Response?> sendPushNotificationToFcm({required String toProfileId,
  required AppProfile fromProfile, required PushNotificationType notificationType,
  String message = "", String referenceId = "", String imgUrl = ""}) async {

  String notificationTitle = "";
  String notificationBody = message;
  http.Response? response;
  String channelId = "";
  String channelKey = "";
  try {
    String toFcmToken = await ProfileFirestore().retrievedFcmToken(toProfileId);

    switch(notificationType) {
      case PushNotificationType.like:
        notificationTitle = AppTranslationConstants.likedYourPost;
        channelId = NotificationChannelConstants.likeChannelId.toString();
        channelKey = NotificationChannelConstants.like;
        break;
      case PushNotificationType.comment:
        notificationTitle = AppTranslationConstants.commentedYourPost;
        channelId = NotificationChannelConstants.commentChannelId.toString();
        channelKey = NotificationChannelConstants.comment;
        break;
      case PushNotificationType.request:
        notificationTitle = AppTranslationConstants.hasSentRequest;
        channelId = NotificationChannelConstants.requestChannelId.toString();
        channelKey = NotificationChannelConstants.request;
        break;
      case PushNotificationType.message:
        notificationTitle = AppTranslationConstants.hasSentMessage;
        channelId = NotificationChannelConstants.messageChannelId.toString();
        channelKey = NotificationChannelConstants.message;
        break;
      case PushNotificationType.eventCreated:
        notificationTitle = AppTranslationConstants.createdAnEvent;
        channelId = NotificationChannelConstants.eventChannelId.toString();
        channelKey = NotificationChannelConstants.event;
        break;
      case PushNotificationType.goingEvent:
        notificationTitle = AppTranslationConstants.goingToYourEvent;
        channelId = NotificationChannelConstants.eventChannelId.toString();
        channelKey = NotificationChannelConstants.event;
        break;
    }

    final body = '''
     {
       "registration_ids": ["$toFcmToken"],
       "data": {
          "title": "${notificationTitle.tr}",
          "body": "$notificationBody",
          "fromId" :"${fromProfile.id}",
          "fromName" :"${fromProfile.name}",
          "fromImgUrl": "${fromProfile.photoUrl}",
          "imgUrl": "$imgUrl",
          "referenceId": "$referenceId",
          "notificationType": "${notificationType.name}",
          "channelId": "$channelId"
          "channelKey": "$channelKey"
        },
        "apns": {
          "content-available" : 1,
          "apns-push-type": "background",
          "headers": {
            "apns-priority": "10"
          }
        }
     }''';

    Uri uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
    response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=${PushNotificationConfig.fcmKey}',
      },
      body: body,
    );
  } catch (e) {
    AppUtilities.logger.e(e.toString());
  }



  return response;

}
