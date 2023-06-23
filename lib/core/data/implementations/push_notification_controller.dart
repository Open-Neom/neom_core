import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_item_firestore.dart';
import '../../app_flavour.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/enums/push_notification_type.dart';

class PushNotificationController extends ChangeNotifier {

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    String referenceId = receivedAction.payload?["referenceId"] ?? "";
    AppUtilities.logger.i("Notification ReferenceId $referenceId retrieved from payload");

    PushNotificationType notificationType = PushNotificationType.values
        .firstWhere((notificationType) => notificationType.value == receivedAction.id);

    switch(notificationType) {
      case PushNotificationType.like:
        Get.toNamed(AppRouteConstants.postDetails, arguments: [referenceId]);
        break;
      case PushNotificationType.comment:
        Get.toNamed(AppRouteConstants.postDetails, arguments: [referenceId]);
        break;
      case PushNotificationType.request:
        Get.toNamed(AppRouteConstants.request);
        break;
      case PushNotificationType.message:
        Get.toNamed(AppRouteConstants.inboxRoom, arguments: [referenceId]);
        break;
      case PushNotificationType.eventCreated:
        Get.toNamed(AppRouteConstants.eventDetails, arguments: [referenceId]);
        break;
      case PushNotificationType.goingEvent:
        Get.toNamed(AppRouteConstants.eventDetails, arguments: [referenceId]);
        break;
      case PushNotificationType.viewProfile:
        Get.toNamed(AppRouteConstants.mateDetails, arguments: referenceId);
        break;
      case PushNotificationType.following:
        Get.toNamed(AppRouteConstants.mateDetails, arguments: referenceId);
        break;
      case PushNotificationType.post:
        Get.toNamed(AppRouteConstants.postDetails, arguments: [referenceId]);
        break;
      case PushNotificationType.blog:
        Get.toNamed(AppRouteConstants.mateBlog, arguments: [referenceId]);
        break;
      case PushNotificationType.appItemAdded:
        Get.toNamed(AppFlavour.getItemDetailsRoute(),
            arguments: [await AppItemFirestore().retrieve(referenceId)]);
        break;
      case PushNotificationType.releaseAppItemAdded:
        Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [referenceId]);
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
