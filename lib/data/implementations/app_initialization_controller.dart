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

    // Get and update FCM token for push notifications
    await _updateFcmTokenIfNeeded(userServiceImpl);

    userServiceImpl.getUserSubscription();
    Future.microtask(() => AppHiveController().fetchCachedData());

    Future.microtask(() => userServiceImpl.verifyLocation());
    Future.microtask(() => Sint.find<NotificationService>().init());

    AppHiveController().setFirstTime(false);
    UserFirestore().updateLastTimeOn(userServiceImpl.user.id);
  }

  /// Updates FCM token in Firestore if it's new or different from stored one
  static Future<void> _updateFcmTokenIfNeeded(UserService userServiceImpl) async {
    try {
      final userId = userServiceImpl.user.id;

      if (userId.isEmpty) {
        AppConfig.logger.w("Cannot update FCM token: userId is empty");
        return;
      }

      final deviceFcmToken = await getFcmToken();

      if (deviceFcmToken.isEmpty) {
        AppConfig.logger.w("Cannot update FCM token: device token is empty");
        return;
      }

      final storedToken = userServiceImpl.user.fcmToken;

      // Update if token is new or different
      if (storedToken.isEmpty || storedToken != deviceFcmToken) {
        AppConfig.logger.d("FCM token changed, updating in Firestore...");
        AppConfig.logger.d("Old token: ${storedToken.isEmpty ? '(empty)' : '${storedToken.substring(0, 20)}...'}");
        AppConfig.logger.d("New token: ${deviceFcmToken.substring(0, 20)}...");

        final success = await UserFirestore().updateFcmToken(userId, deviceFcmToken);

        if (success) {
          AppConfig.logger.i("FCM token updated successfully for user $userId");
          // Update local user object
          userServiceImpl.user.fcmToken = deviceFcmToken;
        } else {
          AppConfig.logger.e("Failed to update FCM token for user $userId");
        }
      } else {
        AppConfig.logger.d("FCM token unchanged, skipping update");
      }
    } catch (e) {
      AppConfig.logger.e("Error updating FCM token: $e");
    }
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
