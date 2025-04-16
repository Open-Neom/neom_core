import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../app_flavour.dart';
import '../../../domain/model/app_profile.dart';
import '../../../utils/app_utilities.dart';
import '../../../utils/constants/app_google_utilities.dart';
import '../../../utils/constants/app_translation_constants.dart';
import '../../../utils/enums/push_notification_type.dart';
import '../../firestore/profile_firestore.dart';
import '../../firestore/user_firestore.dart';

class FirebaseMessagingCalls {

  static Future<http.Response?> sendPrivatePushNotification({
    required String toProfileId, required AppProfile fromProfile,
    required PushNotificationType notificationType, String message = "",
    String referenceId = "", String imgUrl = ""}) async {

    String notificationTitle = "";
    String notificationBody = message;
    http.Response? response;
    int channelId = 0;
    String channelKey = "";
    String profileFCMToken = "";

    try {
      switch(notificationType) {
        case PushNotificationType.like:
          notificationTitle = AppTranslationConstants.likedYourPost;
          channelId = PushNotificationType.like.value;
          channelKey = PushNotificationType.like.name;
          break;
        case PushNotificationType.comment:
          notificationTitle = AppTranslationConstants.commentedYourPost;
          channelId = PushNotificationType.comment.value;
          channelKey = PushNotificationType.comment.name;
          break;
        case PushNotificationType.request:
          notificationTitle = AppTranslationConstants.hasSentRequest;
          channelId = PushNotificationType.request.value;
          channelKey = PushNotificationType.request.name;
          break;
        case PushNotificationType.message:
          notificationTitle = AppTranslationConstants.hasSentMessage;
          channelId = PushNotificationType.message.value;
          channelKey = PushNotificationType.message.name;
          break;
        case PushNotificationType.eventCreated:
          notificationTitle = AppTranslationConstants.eventCreated;
          channelId = PushNotificationType.eventCreated.value;
          channelKey = PushNotificationType.eventCreated.name;
          break;
        case PushNotificationType.goingEvent:
          notificationTitle = AppTranslationConstants.goingToYourEvent;
          channelId = PushNotificationType.goingEvent.value;
          channelKey = PushNotificationType.goingEvent.name;
          break;
        case PushNotificationType.viewProfile:
          notificationTitle = AppTranslationConstants.viewedYourProfile;
          channelId = PushNotificationType.viewProfile.value;
          channelKey = PushNotificationType.viewProfile.name;
          break;
        case PushNotificationType.following:
          notificationTitle = AppTranslationConstants.startedFollowingYou;
          channelId = PushNotificationType.following.value;
          channelKey = PushNotificationType.following.name;
          break;
        case PushNotificationType.post:
          break;
        case PushNotificationType.blog:
          break;
        case PushNotificationType.appItemAdded:
          break;
        case PushNotificationType.releaseAppItemAdded:
          // TODO: Handle this case.
          break;
        case PushNotificationType.chamberPresetAdded:
          // TODO: Handle this case.
      }

      profileFCMToken = await ProfileFirestore().retrievedFcmToken(toProfileId);

      if(profileFCMToken.isNotEmpty) {

        String body = '''
         {
           "registration_ids": ["$profileFCMToken"],
           "data": {
              "title": "${notificationTitle.tr}",
              "body": "$notificationBody",
              "fromId" :"${fromProfile.id}",
              "fromName" :"${fromProfile.name}",
              "fromImgUrl": "${fromProfile.photoUrl}",
              "imgUrl": "$imgUrl",
              "referenceId": "$referenceId",
              "notificationType": "${notificationType.name}",
              "channelId": "$channelId",
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

        Uri uri = Uri.parse(AppGoogleUtilities.fcmGoogleAPIUrl);
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=${AppFlavour.getFcmKey()}',
          },
          body: body,
        );

        if(response.statusCode == 200 || response.statusCode == 201) {
          AppUtilities.logger.i("Firebase Messaginng Response returned as: ${response.statusCode}");
        } else {
          AppUtilities.logger.w("Firebase Messaginng Response returned as: ${response.statusCode}");
        }

      } else {
        AppUtilities.logger.w("Profile $toProfileId has no FCM registered");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return response;

  }

  static Future<http.Response?> sendGlobalPushNotification({
    required AppProfile fromProfile, AppProfile? toProfile,
    required PushNotificationType notificationType, String message = "",
    String referenceId = "", String imgUrl = ""}) async {

    String selfFCM = "";
    String notificationTitle = "";
    String notificationBody = message;
    http.Response? response;
    int channelId = 0;
    String channelKey = "";
    String registrationIds = "";

    try {
      switch(notificationType) {
        case PushNotificationType.like:
          notificationTitle = "${AppTranslationConstants.hasReactedToThePostOf.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.like.value;
          channelKey = PushNotificationType.like.name;
          break;
        case PushNotificationType.comment:
          notificationTitle = "${AppTranslationConstants.commentedThePostOf.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.comment.value;
          channelKey = PushNotificationType.comment.name;
          break;
        case PushNotificationType.request:
          notificationTitle = "${AppTranslationConstants.sentRequestTo.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.request.value;
          channelKey = PushNotificationType.request.name;
          break;
        case PushNotificationType.message:
          notificationTitle = "${AppTranslationConstants.sentMessageTo.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.message.value;
          channelKey = PushNotificationType.message.name;
          break;
        case PushNotificationType.eventCreated:
          notificationTitle = AppTranslationConstants.createdAnEvent;
          channelId = PushNotificationType.eventCreated.value;
          channelKey = PushNotificationType.eventCreated.name;
          break;
        case PushNotificationType.goingEvent:
          notificationTitle = AppTranslationConstants.goingToEvent;
          channelId = PushNotificationType.goingEvent.value;
          channelKey = PushNotificationType.goingEvent.name;
          break;
        case PushNotificationType.viewProfile:
          notificationTitle = "${AppTranslationConstants.viewedProfileOf.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.viewProfile.value;
          channelKey = PushNotificationType.viewProfile.name;
          break;
        case PushNotificationType.following:
          notificationTitle = "${AppTranslationConstants.isFollowingTo.tr} ${toProfile?.name ?? ""}";
          channelId = PushNotificationType.following.value;
          channelKey = PushNotificationType.following.name;
          break;
        case PushNotificationType.post:
          notificationTitle = AppTranslationConstants.hasPostedSomethingNew;
          channelId = PushNotificationType.post.value;
          channelKey = PushNotificationType.post.name;
          break;
        case PushNotificationType.blog:
          notificationTitle = AppTranslationConstants.hasPostedInBlog;
          channelId = PushNotificationType.blog.value;
          channelKey = PushNotificationType.blog.name;
          break;
        case PushNotificationType.appItemAdded:
          notificationTitle = AppTranslationConstants.addedAppItemToList;
          channelId = PushNotificationType.appItemAdded.value;
          channelKey = PushNotificationType.appItemAdded.name;
          break;
        case PushNotificationType.releaseAppItemAdded:
          notificationTitle = AppTranslationConstants.addedReleaseAppItem;
          channelId = PushNotificationType.appItemAdded.value;
          channelKey = PushNotificationType.appItemAdded.name;
          break;
        case PushNotificationType.chamberPresetAdded:
          notificationTitle = AppTranslationConstants.chamberPresetAdded;
          channelId = PushNotificationType.chamberPresetAdded.value;
          channelKey = PushNotificationType.chamberPresetAdded.name;
          break;
      }

      String toProfileFCMToken = "";
      selfFCM = await ProfileFirestore().retrievedFcmToken(fromProfile.id);
      if(toProfile != null) {
        toProfileFCMToken = await ProfileFirestore().retrievedFcmToken(toProfile.id);
      }

      List<String> fcmTokens = await UserFirestore().getFCMTokens();
      for (var fcmToken in fcmTokens) {
        if(fcmToken != selfFCM && fcmToken != toProfileFCMToken) {
          registrationIds = registrationIds.isEmpty
              ? '"$fcmToken"' : '$registrationIds, "$fcmToken"';
        }
      }

      String body = '''
     {
       "registration_ids": [$registrationIds],
       "data": {
          "title": "${notificationTitle.tr}",
          "body": "$notificationBody",
          "fromId" :"${fromProfile.id}",
          "fromName" :"${fromProfile.name}",
          "fromImgUrl": "${fromProfile.photoUrl}",
          "imgUrl": "$imgUrl",
          "referenceId": "$referenceId",
          "notificationType": "${notificationType.name}",
          "channelId": "$channelId",
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

      Uri uri = Uri.parse(AppGoogleUtilities.fcmGoogleAPIUrl);
      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=${AppFlavour.getFcmKey()}',
        },
        body: body,
      );

      AppUtilities.logger.i("Firebase Messaginng Response returned as: ${response.statusCode}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return response;

  }

}
