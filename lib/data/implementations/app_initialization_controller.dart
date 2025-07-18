import 'package:get/get.dart';

import '../../app_config.dart';
import '../../domain/use_cases/audio_player_service.dart';
import '../../domain/use_cases/notification_service.dart';
import '../firestore/user_firestore.dart';
import 'app_hive_controller.dart';
import 'user_controller.dart';

class AppInitializationController {

  static Future<void> runPostLoginTasks() async {
    AppConfig.logger.i("Running post-login initialization tasks...");

    final userController = Get.find<UserController>();
    // Todas las microtareas van aquí
    userController.getUserSubscription();
    Future.microtask(() => UserFirestore().updateLastTimeOn(userController.user.id));
    Future.microtask(() => AppHiveController().fetchCachedData());
    Future.microtask(() => AppHiveController().fetchSettingsData());

    if(userController.user.fcmToken.isEmpty
        || userController.user.fcmToken != userController.fcmToken) {
      Future.microtask(() => UserFirestore().updateFcmToken(userController.user.id, userController.fcmToken));
    }

    Future.microtask(() => userController.verifyLocation());
    Future.microtask(() => Get.find<NotificationService>().init());
    Future.microtask(() => AppHiveController().setFirstTime(false));

  }

  static Future<void> initAudioHandler() async {
    Future.microtask(() => Get.find<AudioPlayerService>().initAudioHandler());
  }

}
