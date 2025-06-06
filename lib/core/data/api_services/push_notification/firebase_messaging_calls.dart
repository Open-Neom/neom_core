import 'dart:convert';

import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../../../app_flavour.dart';
import '../../../domain/model/app_profile.dart';
import '../../../utils/app_utilities.dart';
import '../../../utils/constants/app_google_utilities.dart';
import '../../../utils/constants/app_translation_constants.dart';
import '../../../utils/enums/push_notification_type.dart';
import '../../firestore/constants/app_firestore_constants.dart';
import '../../firestore/profile_firestore.dart';

class FirebaseMessagingCalls {

  static Future<http.Response?> sendPrivatePushNotification({
    required String toProfileId, required AppProfile fromProfile,
    required PushNotificationType notificationType, String message = "",
    String referenceId = "", String imgUrl = ""}) async {


    http.Response? response;

    String profileFCMToken = "";

    try {
      profileFCMToken = await ProfileFirestore().retrievedFcmToken(toProfileId);
      AppUtilities.logger.d("Profile $toProfileId has FCM registered: $profileFCMToken");

      if(profileFCMToken.isNotEmpty) {

        String body = jsonEncode(buildPrivatePayload(notificationType, message, fromProfile, imgUrl, referenceId, profileFCMToken));
        String fcmUrl = AppGoogleUtilities.fcmGoogleAPIUrl.replaceFirst(AppGoogleUtilities.projectId, AppFlavour.getFirebaseProjectId());
        Uri uri = Uri.parse(fcmUrl);

        String? accessToken = await getAccessToken(); // Llama a tu función para obtener el token
        if (accessToken == null || accessToken.isEmpty) {
          AppUtilities.logger.e("Firebase Messaging Error: Access Token es nulo o vacío. No se puede enviar la notificación.");
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
          AppUtilities.logger.i("Firebase Messaginng Response returned as: ${response.statusCode}");
        } else {
          AppUtilities.logger.e("Firebase Messaging Error: ${response.statusCode} - ${response.body}");
        }
      } else {
        AppUtilities.logger.w("Profile $toProfileId has no FCM registered");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return response;

  }

  static Future<http.Response?> sendPublicPushNotification({
    required AppProfile fromProfile, required PushNotificationType notificationType, AppProfile? toProfile,
    String? selfFCM, String message = "", String referenceId = "", String imgUrl = ""}) async {

    http.Response? response;

    try {

      String body = jsonEncode(buildPublicPayload(notificationType, message: message,
          fromProfile: fromProfile, toProfile: toProfile, referenceId: referenceId, imgUrl: imgUrl));

      String fcmUrl = AppGoogleUtilities.fcmGoogleAPIUrl.replaceFirst(AppGoogleUtilities.projectId, AppFlavour.getFirebaseProjectId());
      Uri uri = Uri.parse(fcmUrl);

      String? accessToken = await getAccessToken(); // Llama a tu función para obtener el token
      if (accessToken == null || accessToken.isEmpty) {
        AppUtilities.logger.e("Firebase Messaging Error: Access Token es nulo o vacío. No se puede enviar la notificación.");
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
        AppUtilities.logger.i("Firebase Messaginng Response returned as: ${response.statusCode}");
      } else {
        AppUtilities.logger.e("Firebase Messaging Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return response;

  }

  /// Devuelve un Map<String, dynamic> listo para ser codificado a JSON.
  static Map<String, dynamic> buildPrivatePayload(PushNotificationType notificationType, String message,
      AppProfile fromProfile, String imgUrl, String referenceId, String profileFCMToken) {

    String notificationTitle = "";
    String notificationBody = message;
    int channelId = 0;
    String channelKey = "";

    Map<String, dynamic> fcmPrivatePayload = {};

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
            // "alert": { // Si quieres que APNS muestre una alerta visual
            //   "title": finalNotificationTitle,
            //   "body": messageBodyContent,
            // },
            // "badge": 1, // Opcional: para actualizar el contador del ícono de la app
            // "sound": "default" // Opcional: sonido de la notificación
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
        // "notification": { // Puedes definir aquí también el aspecto de la notificación para Android
        //   "title": finalNotificationTitle,
        //   "body": messageBodyContent,
        //   "image": imgUrl,
        //   "click_action": "FLUTTER_NOTIFICATION_CLICK",
        //   // "channel_id": channelKey, // Si tienes canales de notificación en Android
        // }
      };


      // Construcción del payload FCM v1 completo
      fcmPrivatePayload = {
        "message": {
          "token": profileFCMToken, // Token del dispositivo específico
          "data": dataPayload,
          "apns": apnsPayload,
          "android": androidPayload,
        }
      };
    } catch (e) {
      AppUtilities.logger.e("Error al traducir el mensaje de notificación: $e");
      notificationBody = message; // Fallback al mensaje original si hay un error
    }


    return fcmPrivatePayload;
  }

  static Map<String, dynamic> buildPublicPayload(PushNotificationType notificationType,
    {required AppProfile fromProfile, AppProfile? toProfile, String message = '', String imgUrl = '', String referenceId = ''}) {

    String notificationTitle = "";
    String notificationBody = message;
    int channelId = 0;
    String channelKey = "";
    String toProfileName = toProfile?.name.capitalizeFirst ?? "";

    switch(notificationType) {
      case PushNotificationType.like:
        notificationTitle = "${AppTranslationConstants.hasReactedToThePostOf.tr} $toProfileName";
        channelId = PushNotificationType.like.value;
        channelKey = PushNotificationType.like.name;
        break;
      case PushNotificationType.comment:
        notificationTitle = "${AppTranslationConstants.commentedThePostOf.tr} $toProfileName";
        channelId = PushNotificationType.comment.value;
        channelKey = PushNotificationType.comment.name;
        break;
      case PushNotificationType.request:
        notificationTitle = "${AppTranslationConstants.sentRequestTo.tr} $toProfileName";
        channelId = PushNotificationType.request.value;
        channelKey = PushNotificationType.request.name;
        break;
      case PushNotificationType.message:
        notificationTitle = "${AppTranslationConstants.sentMessageTo.tr} $toProfileName";
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
        notificationTitle = "${AppTranslationConstants.viewedProfileOf.tr} $toProfileName";
        channelId = PushNotificationType.viewProfile.value;
        channelKey = PushNotificationType.viewProfile.name;
        break;
      case PushNotificationType.following:
        notificationTitle = "${AppTranslationConstants.isFollowingTo.tr} $toProfileName";
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

    Map<String, dynamic> dataPayload = {
      "title": notificationTitle.tr,
      "body": notificationBody,
      "fromId" : fromProfile.id,
      "fromName" : fromProfile.name,
      "fromImgUrl": fromProfile.photoUrl,
      "toId": toProfile?.id,
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

    // Construcción del payload FCM v1 completo
    Map<String, dynamic> fcmPublicPayload = {
      "message": {
        "topic": AppFirestoreConstants.allUsers,
        "data": dataPayload,
        "apns": apnsPayload,
        "android": androidPayload,
      }
    };

    return fcmPublicPayload;
  }


  static Future<String?> getAccessToken() async {
    AppUtilities.logger.d("Obteniendo token de acceso OAuth2 para Firebase Cloud Messaging");

    String? accessToken;
    String serviceAccount = jsonEncode(AppFlavour.serviceAccount);

    try {
      auth.ServiceAccountCredentials credentials = auth.ServiceAccountCredentials.fromJson(serviceAccount);
      var scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      auth.AccessCredentials accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
          credentials, scopes, http.Client()); // Necesitas un http.Client
      accessToken = accessCredentials.accessToken.data;
    } catch (e) {
      AppUtilities.logger.e("Error obteniendo token de acceso OAuth2: $e");

    }

    return accessToken;
  }

}
