import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../../../neom_commons.dart';
import 'push_notification_controller.dart';

class PushNotificationService {

  var logger = AppUtilities.logger;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;
  static String referenceId = "referenceId";

  static Future<NotificationSettings> initNotifications({required bool debug}) async {

    NotificationSettings notificationSettings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    try {
      AwesomeNotifications().initialize(
        AppAssets.iconResource,
        [
          NotificationChannel(
              channelGroupKey: PushNotificationType.like.name,
              channelKey: PushNotificationType.like.name,
              channelName: 'Like Channel',
              channelDescription: 'Like channel',
              importance: NotificationImportance.High),
          NotificationChannel(
              channelGroupKey: PushNotificationType.comment.name,
              channelKey: PushNotificationType.comment.name,
              channelName: 'Comment Channel',
              channelDescription: 'Comment channel',
              importance: NotificationImportance.High),
          NotificationChannel(
              channelGroupKey: PushNotificationType.request.name,
              channelKey: PushNotificationType.request.name,
              channelName: 'Request Channel',
              channelDescription: 'Request channel',
              importance: NotificationImportance.Max),
          NotificationChannel(
              channelGroupKey: PushNotificationType.message.name,
              channelKey: PushNotificationType.message.name,
              channelName: 'Message Channel',
              channelDescription: 'Message channel',
              importance: NotificationImportance.Max),
          NotificationChannel(
              channelGroupKey: PushNotificationType.eventCreated.name,
              channelKey: PushNotificationType.eventCreated.name,
              channelName: 'Event Channel',
              channelDescription: 'Event channel',
              importance: NotificationImportance.Max),
          NotificationChannel(
              channelGroupKey: PushNotificationType.goingEvent.name,
              channelKey: PushNotificationType.goingEvent.name,
              channelName: 'Event Channel',
              channelDescription: 'Event channel',
              importance: NotificationImportance.Max),
          NotificationChannel(
              channelGroupKey: PushNotificationType.viewProfile.name,
              channelKey: PushNotificationType.viewProfile.name,
              channelName: 'View Profile Channel',
              channelDescription: 'View Profile channel',
              importance: NotificationImportance.Low),
          NotificationChannel(
              channelGroupKey: PushNotificationType.following.name,
              channelKey: PushNotificationType.following.name,
              channelName: 'Following Channel',
              channelDescription: 'Following channel',
              importance: NotificationImportance.Low),
          NotificationChannel(
              channelGroupKey: PushNotificationType.post.name,
              channelKey: PushNotificationType.post.name,
              channelName: 'Post Channel',
              channelDescription: 'Blog Channel',
              importance: NotificationImportance.Low),
          NotificationChannel(
              channelGroupKey: PushNotificationType.blog.name,
              channelKey: PushNotificationType.blog.name,
              channelName: 'Blog Channel',
              channelDescription: 'Blog Channel',
              importance: NotificationImportance.Low),
          NotificationChannel(
              channelGroupKey: PushNotificationType.appItemAdded.name,
              channelKey: PushNotificationType.appItemAdded.name,
              channelName: 'App Item Channel',
              channelDescription: 'App Item Channel',
              importance: NotificationImportance.Low)
        ],
        channelGroups: [
          NotificationChannelGroup(channelGroupKey: PushNotificationType.like.name, channelGroupName: PushNotificationType.like.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.comment.name, channelGroupName: PushNotificationType.comment.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.request.name, channelGroupName: PushNotificationType.request.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.message.name, channelGroupName: PushNotificationType.message.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.eventCreated.name, channelGroupName: PushNotificationType.eventCreated.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.goingEvent.name, channelGroupName: PushNotificationType.goingEvent.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.viewProfile.name, channelGroupName: PushNotificationType.viewProfile.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.following.name, channelGroupName: PushNotificationType.following.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.post.name, channelGroupName: PushNotificationType.post.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.blog.name, channelGroupName: PushNotificationType.blog.name),
          NotificationChannelGroup(channelGroupKey: PushNotificationType.appItemAdded.name, channelGroupName: PushNotificationType.appItemAdded.name),
        ],
        debug: debug,
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return notificationSettings;
  }

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
        case PushNotificationType.viewProfile:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.Default);
          break;
        case PushNotificationType.following:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.Default);
          break;
        case PushNotificationType.post:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.BigPicture);
          break;
        case PushNotificationType.blog:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Social, NotificationLayout.BigText);
          break;
        case PushNotificationType.appItemAdded:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Recommendation, NotificationLayout.BigPicture);
          break;
        case PushNotificationType.releaseAppItemAdded:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Recommendation, NotificationLayout.BigPicture);
          break;
        case PushNotificationType.chamberPresetAdded:
          buildPushNotification(pushNotificationMessage,
              NotificationCategory.Recommendation, NotificationLayout.BigPicture);
          break;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  static void buildPushNotification(PushNotificationMessage pushNotificationMessage,
      NotificationCategory notificationCategory, NotificationLayout notificationLayout) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: pushNotificationMessage.channelId,
          channelKey: pushNotificationMessage.channelKey,
          largeIcon: pushNotificationMessage.fromImgUrl.isNotEmpty
              ? pushNotificationMessage.fromImgUrl : AppFlavour.getAppLogoUrl(),
          category: notificationCategory,
          title: "${pushNotificationMessage.fromName} ${pushNotificationMessage.title.tr}",
          payload: {referenceId: pushNotificationMessage.referenceId},
          body: pushNotificationMessage.body,
          bigPicture: pushNotificationMessage.imgUrl?.isNotEmpty ?? false ? pushNotificationMessage.imgUrl
              : pushNotificationMessage.fromImgUrl.isNotEmpty ? pushNotificationMessage.fromImgUrl : AppFlavour.getNoImageUrl(),
          notificationLayout: notificationLayout,
        )
    );
  }

  static void actionStreamListener() {
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: PushNotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod: PushNotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod: PushNotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: PushNotificationController.onDismissActionReceivedMethod
    );
  }

}
