import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../domain/model/push_notification_message.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/enums/push_notification_type.dart';
import '../api_services/push_notification/notification_channel_constants.dart';

class PushNotificationService {

  var logger = AppUtilities.logger;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;


  static Future<void> backgroundHandler(RemoteMessage message) async {
    AppUtilities.logger.d('onBackground Handler ${message.messageId}');

    try {
      selectPushNotificationForFcm(message);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  static Future<void> onMessageHandler(RemoteMessage message) async {
    AppUtilities.logger.d('onMessageHandler Handler ${message.messageId}');

    try {
      selectPushNotificationForFcm(message);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  static Future<void> onMessageOpenApp(RemoteMessage message) async {
    AppUtilities.logger.d('onMessageOpenApp Handler ${message.messageId}');

    try {
      selectPushNotificationForFcm(message);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  static void selectPushNotificationForFcm(RemoteMessage message) {
    try {
      PushNotificationMessage pushNotificationMessage = PushNotificationMessage.fromMessageData(message.data);
      switch(pushNotificationMessage.type) {
        case PushNotificationType.like:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.BigPicture);
          break;
        case PushNotificationType.comment:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.BigText);
          break;
        case PushNotificationType.request:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.Inbox);
          break;
        case PushNotificationType.message:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Message, NotificationLayout.Inbox);
          break;
        case PushNotificationType.eventCreated:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Event, NotificationLayout.BigPicture);
          break;
        case PushNotificationType.goingEvent:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Event, NotificationLayout.BigPicture);
          break;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  static void buildPushNotification(PushNotificationMessage pushNotificationMessage,
      NotificationCategory notificationCategory, NotificationLayout notificationLayout) {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
          category: notificationCategory,
          id: pushNotificationMessage.channelId,
          channelKey: pushNotificationMessage.channelKey,
          title: "${pushNotificationMessage.fromName} ${pushNotificationMessage.title.tr}",
          payload: {"referenceId": pushNotificationMessage.referenceId},
          body: pushNotificationMessage.body,
          bigPicture: pushNotificationMessage.imgUrl?.isNotEmpty ?? false ? pushNotificationMessage.imgUrl
              : pushNotificationMessage.fromImgUrl.isNotEmpty ? pushNotificationMessage.fromImgUrl : AppFlavour.getNoImageUrl(),
          notificationLayout: notificationLayout,
        )
    );
  }


  static void initNotifications() {
    AwesomeNotifications().initialize(
      AppAssets.iconResource,
      [
        NotificationChannel(
            channelGroupKey: 'likes',
            channelKey: NotificationChannelConstants.like,
            channelName: 'Like Channel',
            channelDescription: 'Like channel',
            importance: NotificationImportance.High),
        NotificationChannel(
            channelGroupKey: 'comments',
            channelKey: NotificationChannelConstants.comment,
            channelName: 'Comment Channel',
            channelDescription: 'Comment channel',
            importance: NotificationImportance.High),
        NotificationChannel(
            channelGroupKey: 'requests',
            channelKey: NotificationChannelConstants.request,
            channelName: 'Request Channel',
            channelDescription: 'Request channel',
            importance: NotificationImportance.Max),
        NotificationChannel(
            channelGroupKey: 'messages',
            channelKey: NotificationChannelConstants.message,
            channelName: 'Message Channel',
            channelDescription: 'Message channel',
            importance: NotificationImportance.Max),
        NotificationChannel(
            channelGroupKey: 'events',
            channelKey: NotificationChannelConstants.event,
            channelName: 'Event Channel',
            channelDescription: 'Event channel',
            importance: NotificationImportance.Max),
      ],
      debug: true,
      channelGroups: [
        NotificationChannelGroup(channelGroupKey: 'likes', channelGroupName: 'Likes Channel'),
        NotificationChannelGroup(channelGroupKey: 'comments', channelGroupName: 'Comments Channel'),
        NotificationChannelGroup(channelGroupKey: 'requests', channelGroupName: 'Requests Channel'),
        NotificationChannelGroup(channelGroupKey: 'messages', channelGroupName: 'Messages Channel'),
        NotificationChannelGroup(channelGroupKey: 'events', channelGroupName: 'Events Channel'),
      ],
    );
  }


  static void actionStreamListener() {
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:    NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  NotificationController.onDismissActionReceivedMethod
    );
  }

}

class NotificationController {

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    String referenceId = receivedAction.payload?["referenceId"] ?? "";
    AppUtilities.logger.i("Notification ReferenceId $referenceId retrieved from payload");
    switch(receivedAction.id) {
      case NotificationChannelConstants.likeChannelId:
        Get.toNamed(AppRouteConstants.postDetails, arguments: [referenceId]);
        break;
      case NotificationChannelConstants.commentChannelId:
        Get.toNamed(AppRouteConstants.postDetails, arguments: [referenceId]);
        break;
      case NotificationChannelConstants.requestChannelId:
        Get.toNamed(AppRouteConstants.request);
        break;
      case NotificationChannelConstants.messageChannelId:
        Get.toNamed(AppRouteConstants.inboxRoom, arguments: [referenceId]);
        break;
      case NotificationChannelConstants.eventChannelId:
        Get.toNamed(AppRouteConstants.eventDetails, arguments: [referenceId]);
        break;
    }
  }

  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

}
