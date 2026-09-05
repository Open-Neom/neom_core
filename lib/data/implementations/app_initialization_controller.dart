import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../domain/use_cases/audio_player_invoker_service.dart';
import '../../domain/use_cases/notification_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/fcm_token_policy.dart';
import '../../utils/neom_error_logger.dart';
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
    Future.microtask(
      () => AppHiveController().fetchCachedDataForSession(
        hasAuthenticatedSession: AppConfig.instance.canPersistUserActivity,
      ),
    );

    Future.microtask(() => userServiceImpl.verifyLocation());
    if (!kIsWeb) {
      Future.microtask(() => Sint.find<NotificationService>().init());
    }

    AppHiveController().setFirstTime(false);
    UserFirestore().updateLastTimeOn(userServiceImpl.user.id);
  }

  /// Updates FCM token in Firestore if it's new or different from stored one
  static Future<void> _updateFcmTokenIfNeeded(
    UserService userServiceImpl,
  ) async {
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
        AppConfig.logger.d(
          "Old token: ${storedToken.isEmpty ? '(empty)' : '${storedToken.substring(0, 20)}...'}",
        );
        AppConfig.logger.d("New token: ${deviceFcmToken.substring(0, 20)}...");

        final success = await UserFirestore().updateFcmToken(
          userId,
          deviceFcmToken,
        );

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
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: '_updateFcmTokenIfNeeded',
      );
    }
  }

  static Future<void> initAudioHandler() async {
    if (kIsWeb) return;
    if (Sint.isRegistered<AudioPlayerInvokerService>()) {
      Future.microtask(
        () => Sint.find<AudioPlayerInvokerService>().initAudioHandler(),
      );
    } else {
      AppConfig.logger.d(
        "AudioPlayerInvokerService is not registered, skipping initAudioHandler.",
      );
    }
  }

  static Future<String> getFcmToken() async {
    return resolveFcmToken(
      isWeb: kIsWeb,
      skipForBackend: FcmTokenPolicy.forCurrentBackend(),
      supportsMessaging: () => FirebaseMessaging.instance.isSupported(),
      loadToken: () => FirebaseMessaging.instance.getToken(),
      subscribeToTopic: (topic) =>
          FirebaseMessaging.instance.subscribeToTopic(topic),
    );
  }

  /// Resolves an FCM token without allowing an optional notification feature
  /// to interrupt login or onboarding.
  ///
  /// Web support is checked before `getToken()`, and browser-side failures are
  /// treated as an unavailable capability. Native failures still propagate to
  /// [_updateFcmTokenIfNeeded], preserving the existing Android/iOS handling.
  @visibleForTesting
  static Future<String> resolveFcmToken({
    required bool isWeb,
    required bool skipForBackend,
    required Future<bool> Function() supportsMessaging,
    required Future<String?> Function() loadToken,
    required Future<void> Function(String topic) subscribeToTopic,
  }) async {
    if (skipForBackend) {
      AppConfig.logger.d(
        'FCM token registration skipped for Firebase Emulator/demo project.',
      );
      return '';
    }

    if (isWeb) {
      try {
        if (!await supportsMessaging()) {
          AppConfig.logger.i(
            'FCM token registration skipped: browser does not support '
            'Firebase Messaging.',
          );
          return '';
        }

        final fcmToken = await loadToken() ?? '';
        if (fcmToken.isEmpty) {
          AppConfig.logger.w('FCM Token is empty');
        }
        return fcmToken;
      } catch (e) {
        // Web Push is optional. Browsers without the required APIs (or with
        // storage/notifications disabled) can throw even during isSupported.
        AppConfig.logger.w(
          'FCM token registration unavailable in this browser: $e',
        );
        return '';
      }
    }

    final fcmToken = await loadToken() ?? '';
    if (fcmToken.isNotEmpty) {
      await subscribeToTopic(AppFirestoreConstants.allUsers);
      AppConfig.logger.d(
        'FCM Token $fcmToken subscribed to topic '
        '${AppFirestoreConstants.allUsers}.',
      );
    } else {
      AppConfig.logger.w('FCM Token is empty');
    }

    return fcmToken;
  }
}
