import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:sint/sint.dart';

import '../../../app_config.dart';
import '../../../app_properties.dart';
import '../../../domain/model/app_profile.dart';
import '../../../utils/constants/app_google_utilities.dart';
import '../../../utils/enums/push_notification_type.dart';
import '../../firestore/constants/app_firestore_constants.dart';
import '../../firestore/profile_firestore.dart';

class FirebaseMessagingCalls {

  /// Maximum number of push notifications to send when notifying multiple users.
  /// This helps reduce FCM costs by limiting mass notifications.
  /// Users beyond this limit will still get ActivityFeed notifications in-app.
  static const int maxPushNotificationsPerBatch = 100;

  /// Sends push notifications to multiple users with a limit.
  /// Only the first [maxPushNotificationsPerBatch] users will receive push notifications.
  /// All users should receive ActivityFeed notifications separately.
  ///
  /// Returns the number of notifications actually sent.
  static Future<int> sendBatchPushNotifications({
    required List<String> toProfileIds,
    required AppProfile fromProfile,
    required PushNotificationType notificationType,
    required String title,
    required String message,
    String referenceId = "",
    String imgUrl = "",
    int? maxNotifications,
  }) async {
    final limit = maxNotifications ?? maxPushNotificationsPerBatch;
    final limitedIds = toProfileIds.take(limit).toList();

    AppConfig.logger.d('Sending batch push notifications: ${limitedIds.length}/${toProfileIds.length} '
        '(limit: $limit)');

    int sentCount = 0;
    for (final profileId in limitedIds) {
      final response = await sendPrivatePushNotification(
        toProfileId: profileId,
        fromProfile: fromProfile,
        notificationType: notificationType,
        title: title,
        message: message,
        referenceId: referenceId,
        imgUrl: imgUrl,
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        sentCount++;
      }
    }

    AppConfig.logger.i('Batch push notifications sent: $sentCount/${limitedIds.length}');
    return sentCount;
  }

  /// Sends a push notification from one user to another.
  /// Returns null if recipient has no FCM token registered.
  static Future<http.Response?> sendPrivatePushNotification({
    required String toProfileId, required AppProfile fromProfile,
    required PushNotificationType notificationType, required String title,
    required String message, String referenceId = "", String imgUrl = ""}) async {

    http.Response? response;

    try {
      // Get recipient's FCM token
      String recipientFcmToken = await ProfileFirestore().retrievedFcmToken(toProfileId);

      if (recipientFcmToken.isEmpty) {
        AppConfig.logger.w("Cannot send push notification: recipient $toProfileId has no FCM token. "
            "They may not have logged in recently or notifications are disabled on their device.");
        return null;
      }

      AppConfig.logger.d("Sending push notification to profile $toProfileId");
      AppConfig.logger.d("FCM Token: ${recipientFcmToken.substring(0, 20)}...");

      // Build the payload
      String body = jsonEncode(buildPrivatePayload(
        notificationType,
        fromProfile: fromProfile,
        title: title,
        message: message,
        imgUrl: imgUrl,
        referenceId: referenceId,
        profileFCMToken: recipientFcmToken,
      ));

      // Get OAuth access token
      String? accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        AppConfig.logger.e("Firebase Messaging Error: Could not obtain OAuth access token");
        return null;
      }

      // Build FCM URL
      String fcmUrl = AppGoogleUtilities.fcmGoogleAPIUrl.replaceFirst(
        AppGoogleUtilities.projectId,
        AppProperties.getFirebaseProjectId(),
      );

      // Send the notification
      response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppConfig.logger.i("Push notification sent successfully to $toProfileId");
      } else {
        AppConfig.logger.e("Firebase Messaging Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      AppConfig.logger.e("Error sending push notification: $e");
    }

    return response;
  }

  static Future<http.Response?> sendPublicPushNotification({
    required AppProfile fromProfile, required String toProfileId,
    required PushNotificationType notificationType, required String title, String message = '',
     String referenceId = "", String imgUrl = ""}) async {

    http.Response? response;

    try {

      String body = jsonEncode(buildPublicPayload(notificationType, title: title, message: message,
          fromProfile: fromProfile, toProfileId: toProfileId, referenceId: referenceId, imgUrl: imgUrl));

      String fcmUrl = AppGoogleUtilities.fcmGoogleAPIUrl.replaceFirst(AppGoogleUtilities.projectId, AppProperties.getFirebaseProjectId());
      Uri uri = Uri.parse(fcmUrl);

      String? accessToken = await getAccessToken(); // Llama a tu función para obtener el token
      if (accessToken == null || accessToken.isEmpty) {
        AppConfig.logger.e("Firebase Messaging Error: Access Token es nulo o vacío. No se puede enviar la notificación.");
        return null; // O manejar el error de otra forma
      }

      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      if(response.statusCode == 200 || response.statusCode == 201) {
        AppConfig.logger.i("Firebase Messaginng Response returned as: ${response.statusCode}");
      } else {
        AppConfig.logger.e("Firebase Messaging Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return response;

  }

  /// Builds FCM v1 payload for private (user-to-user) notifications.
  /// Includes both 'notification' (for visual display) and 'data' (for app handling).
  static Map<String, dynamic> buildPrivatePayload(PushNotificationType notificationType, {
    required AppProfile fromProfile, required String title, required String message,
    String imgUrl = '', String referenceId = '', String profileFCMToken = ''}) {

    String notificationTitle = fromProfile.name;
    String notificationBody = message.isNotEmpty ? message : title.tr;
    int channelId = notificationType.value;
    String channelKey = notificationType.name;

    Map<String, dynamic> fcmPrivatePayload = {};

    try {
      // Notification payload - THIS IS REQUIRED for visible notifications
      Map<String, dynamic> notificationPayload = {
        "title": notificationTitle,
        "body": notificationBody,
      };

      // Data payload - for app to handle when notification is tapped
      Map<String, dynamic> dataPayload = {
        "title": title.tr,
        "body": notificationBody,
        "fromId": fromProfile.id,
        "fromName": fromProfile.name,
        "fromImgUrl": fromProfile.photoUrl,
        "imgUrl": imgUrl,
        "referenceId": referenceId,
        "notificationType": notificationType.name,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "channelId": channelId.toString(),
        "channelKey": channelKey,
        "isPublic": "false",
      };

      // Android specific configuration
      Map<String, dynamic> androidPayload = {
        "priority": "high",
        "notification": {
          "channel_id": channelKey,
          "sound": "default",
          "default_vibrate_timings": true,
          "default_light_settings": true,
        },
      };

      // iOS (APNS) specific configuration - MUST be 'alert' type for visible notifications
      Map<String, dynamic> apnsPayload = {
        "payload": {
          "aps": {
            "alert": {
              "title": notificationTitle,
              "body": notificationBody,
            },
            "sound": "default",
            "badge": 1,
          }
        },
        "headers": {
          "apns-push-type": "alert",
          "apns-priority": "10",
        }
      };

      // Build the complete message payload
      Map<String, dynamic> messagePayload = {
        "token": profileFCMToken,
        "notification": notificationPayload,
        "data": dataPayload,
        "android": androidPayload,
        "apns": apnsPayload,
      };

      // FCM v1 payload structure
      fcmPrivatePayload = {
        "message": messagePayload
      };

      AppConfig.logger.d("FCM Payload built for token: ${profileFCMToken.substring(0, 20)}...");
    } catch (e) {
      AppConfig.logger.e("Error building FCM payload: $e");
    }

    return fcmPrivatePayload;
  }

  /// Builds FCM v1 payload for public (topic-based) notifications.
  /// Sends to all users subscribed to the topic.
  static Map<String, dynamic> buildPublicPayload(PushNotificationType notificationType,
    {required AppProfile fromProfile, required String title, required String message,
      String toProfileId = '', String imgUrl = '', String referenceId = ''}) {

    String notificationTitle = title.tr;
    String notificationBody = message.isNotEmpty ? message : fromProfile.name;
    int channelId = notificationType.value;
    String channelKey = notificationType.name;

    // Notification payload for visible notifications
    Map<String, dynamic> notificationPayload = {
      "title": notificationTitle,
      "body": notificationBody,
    };

    // Data payload for app handling
    Map<String, dynamic> dataPayload = {
      "title": notificationTitle,
      "body": notificationBody,
      "fromId": fromProfile.id,
      "fromName": fromProfile.name,
      "fromImgUrl": fromProfile.photoUrl,
      "toId": toProfileId,
      "imgUrl": imgUrl,
      "referenceId": referenceId,
      "notificationType": notificationType.name,
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "channelId": channelId.toString(),
      "channelKey": channelKey,
      "isPublic": "true",
    };

    // Android specific configuration
    Map<String, dynamic> androidPayload = {
      "priority": "high",
      "notification": {
        "channel_id": channelKey,
        "sound": "default",
      },
    };

    // iOS (APNS) specific configuration
    Map<String, dynamic> apnsPayload = {
      "payload": {
        "aps": {
          "alert": {
            "title": notificationTitle,
            "body": notificationBody,
          },
          "sound": "default",
        }
      },
      "headers": {
        "apns-push-type": "alert",
        "apns-priority": "10",
      }
    };

    Map<String, dynamic> messagePayload = {
      "topic": AppFirestoreConstants.allUsers,
      "notification": notificationPayload,
      "data": dataPayload,
      "android": androidPayload,
      "apns": apnsPayload,
    };

    // FCM v1 payload structure
    Map<String, dynamic> fcmPublicPayload = {
      "message": messagePayload
    };

    AppConfig.logger.d("FCM Public Payload built for topic: ${AppFirestoreConstants.allUsers}");
    return fcmPublicPayload;
  }


  static Future<String?> getAccessToken() async {
    AppConfig.logger.d("Obteniendo token de acceso OAuth2 para Firebase Cloud Messaging");

    String? accessToken;
    String serviceAccount = jsonEncode(AppProperties.serviceAccount);

    try {
      auth.ServiceAccountCredentials credentials = auth.ServiceAccountCredentials.fromJson(serviceAccount);
      var scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      auth.AccessCredentials accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
          credentials, scopes, http.Client()); // Necesitas un http.Client
      accessToken = accessCredentials.accessToken.data;
    } catch (e) {
      AppConfig.logger.e("Error obteniendo token de acceso OAuth2: $e");

    }

    return accessToken;
  }

}
