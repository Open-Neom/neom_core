import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../domain/use_cases/audio_player_invoker_service.dart';
import '../../domain/use_cases/notification_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../firestore/constants/app_firestore_constants.dart';
import '../firestore/user_firestore.dart';
import 'app_hive_controller.dart';

class AppInitializationController {

  static Future<void> runPostLoginTasks() async {
    AppConfig.logger.i("Running post-login initialization tasks...");

    final userServiceImpl = Sint.find<UserService>();

    // Todas las microtareas van aquí
    await AppHiveController().fetchSettingsData();
    String deviceFcmToken = await getFcmToken();

    userServiceImpl.getUserSubscription();
    Future.microtask(() => AppHiveController().fetchCachedData());

    if(userServiceImpl.user.fcmToken.isEmpty || userServiceImpl.user.fcmToken != deviceFcmToken) {
      UserFirestore().updateFcmToken(userServiceImpl.user.id, deviceFcmToken);
    }

    Future.microtask(() => userServiceImpl.verifyLocation());
    Future.microtask(() => Sint.find<NotificationService>().init());

    AppHiveController().setFirstTime(false);
    UserFirestore().updateLastTimeOn(userServiceImpl.user.id);

  }

  static Future<void> initAudioHandler() async {
    Future.microtask(() => Sint.find<AudioPlayerInvokerService>().initAudioHandler());
  }

  static Future<String> getFcmToken() async {
    String fcmToken = await FirebaseMessaging.instance.getToken() ?? "";

    if(fcmToken.isNotEmpty) {
      await FirebaseMessaging.instance.subscribeToTopic(AppFirestoreConstants.allUsers);
      AppConfig.logger.d("FCM Token $fcmToken subscribed to topic ${AppFirestoreConstants.allUsers}.");
    } else {
      AppConfig.logger.w("FCM Token is empty");
    }

    return fcmToken;
  }

}
