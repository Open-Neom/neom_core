import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../../app_properties.dart';
import '../../../domain/model/app_profile.dart';
import '../../../utils/constants/app_google_utilities.dart';
import '../../../utils/enums/push_notification_type.dart';
import '../../firestore/constants/app_firestore_constants.dart';
import '../../firestore/profile_firestore.dart';

class FirebaseMessagingCalls {

  static Future<http.Response?> sendPrivatePushNotification({
    required String toProfileId, required AppProfile fromProfile,
    required PushNotificationType notificationType, required String title,
    required String message, String referenceId = "", String imgUrl = ""}) async {


    http.Response? response;

    String profileFCMToken = "";

    try {
      profileFCMToken = await ProfileFirestore().retrievedFcmToken(toProfileId);
      AppConfig.logger.d("Profile $toProfileId has FCM registered: $profileFCMToken");

      if(profileFCMToken.isNotEmpty) {

        String body = jsonEncode(buildPrivatePayload(notificationType, fromProfile: fromProfile, title: title, message: message,
            imgUrl: imgUrl, referenceId: referenceId, profileFCMToken: profileFCMToken));
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
      } else {
        AppConfig.logger.w("Profile $toProfileId has no FCM registered");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
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

  //Devuelve un Map<String, dynamic> listo para ser codificado a JSON.
  static Map<String, dynamic> buildPrivatePayload(PushNotificationType notificationType, {
    required AppProfile fromProfile, required String title, required String message,
    String imgUrl = '', String referenceId = '', String profileFCMToken = ''}) {

    String notificationTitle = "";
    String notificationBody = message;
    int channelId = 0;
    String channelKey = "";

    Map<String, dynamic> fcmPrivatePayload = {};

    notificationTitle = title;
    channelId = notificationType.value;
    channelKey = notificationType.name;

    try {

      Map<String, dynamic> dataPayload = {
        "title": notificationTitle.tr,
        "body": notificationBody,
        "fromId" : fromProfile.id,
        "fromName" : fromProfile.name,
        "fromImgUrl": fromProfile.photoUrl,
        "imgUrl": imgUrl,
        "referenceId": referenceId,
        "notificationType": notificationType.name,
        "click_action": "FLUTTER_NOTIFICATION_CLICK", // Acción estándar para Flutter
        "channelId": channelId.toString(), // Los valores en data suelen ser strings
        "channelKey": channelKey,
        "isPublic": "false",
      };

      // Configuración específica de APNS (iOS)
      Map<String, dynamic> apnsPayload = {
        "payload": {
          "aps": {
            "content-available": 1, // Para notificaciones silenciosas o de datos en iOS
          }
        },
        "headers": {
          "apns-push-type": "background", // o 'alert' si tienes la sección "alert" en aps
          "apns-priority": "5", // 5 para content-available, 10 para alertas visuales
        }
      };

      // Configuración específica de Android (opcional, para personalizar cómo Android maneja la notificación)
      Map<String, dynamic> androidPayload = {
        "priority": "high", // "normal" o "high"
      };

      Map<String, dynamic> messagePayload = {
        "token": profileFCMToken,
        "data": dataPayload,
        "android": androidPayload,
      };

      if(Platform.isIOS) {
        messagePayload['apns'] = apnsPayload;
      }

      // Construcción del payload FCM v1 completo
      fcmPrivatePayload = {
        "message": messagePayload
      };
    } catch (e) {
      AppConfig.logger.e("Error al traducir el mensaje de notificación: $e");
      notificationBody = message; // Fallback al mensaje original si hay un error
    }


    return fcmPrivatePayload;
  }

  static Map<String, dynamic> buildPublicPayload(PushNotificationType notificationType,
    {required AppProfile fromProfile, required String title, required String message,
      String toProfileId = '', String imgUrl = '', String referenceId = ''}) {

    String notificationTitle = "";
    String notificationBody = message;
    int channelId = 0;
    String channelKey = "";
    // String toProfileName = toProfile?.name.capitalizeFirst ?? "";

    notificationTitle = title;
    channelId = notificationType.value;
    channelKey = notificationType.name;

    Map<String, dynamic> dataPayload = {
      "title": notificationTitle.tr,
      "body": notificationBody,
      "fromId" : fromProfile.id,
      "fromName" : fromProfile.name,
      "fromImgUrl": fromProfile.photoUrl,
      "toId": toProfileId,
      "imgUrl": imgUrl,
      "referenceId": referenceId,
      "notificationType": notificationType.name,
      "click_action": "FLUTTER_NOTIFICATION_CLICK", // Acción estándar para Flutter
      "channelId": channelId.toString(), // Los valores en data suelen ser strings
      "channelKey": channelKey,
      "isPublic": "true", // Public notifications are not private
    };

    // Configuración específica de APNS (iOS)
    Map<String, dynamic> apnsPayload = {
      "payload": {
        "aps": {
          "content-available": 1, // Para notificaciones silenciosas o de datos en iOS
        }
      },
      "headers": {
        "apns-push-type": "background", // o 'alert' si tienes la sección "alert" en aps
        "apns-priority": "5", // 5 para content-available, 10 para alertas visuales
      }
    };

    Map<String, dynamic> androidPayload = {
      "priority": "high", // "normal" o "high"
    };

    Map<String, dynamic> messagePayload = {
      "topic": AppFirestoreConstants.allUsers,
      "data": dataPayload,
      "android": androidPayload,
    };

    if(Platform.isIOS) {
      messagePayload['apns'] = apnsPayload;
    }

    // Construcción del payload FCM v1 completo
    Map<String, dynamic> fcmPublicPayload = {
      "message": messagePayload
    };

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
