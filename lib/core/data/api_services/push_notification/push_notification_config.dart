import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_route_constants.dart';


//Colocar en Root para cambiar context segun pagina.

class PushNotificationConfig {

  Future<void> initNotificationsUser(BuildContext contextUser) async {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    AwesomeNotifications().setListeners(onActionReceivedMethod: (event) async {
      if (event.toMap()['payload']['typeNotification'] == 'chat') {
        Get.toNamed(AppRouteConstants.inbox);
        Navigator.pushNamed(
          contextUser,
          '/chat',
        );
      }
    }
    );
  }
}
