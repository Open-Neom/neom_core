import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_route_constants.dart';


//Colocar en Root para cambiar context segun pagina.

class PushNotificationConfig {

  static const String fcmKey = "AAAAZ5CTaQg:APA91bEeo7jD3lnkYZNOsPGhQuebihyOvUkYeld9ADHr5sRCAoKJJgy3to353DEXX6Dn_69We4M2wfHcT4mNHVYJPbVmW4wWDsTA6VbVvVvnsM8jDgOhUFZYk0xhEHOwWv4Q8gvrLa6";

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
