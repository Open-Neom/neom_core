import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/implementations/app_initialization_controller.dart';

void main() {
  group('AppInitializationController.resolveFcmToken', () {
    test('emulator/demo backend never touches Firebase Messaging', () async {
      var supportChecks = 0;
      var tokenLoads = 0;
      var subscriptions = 0;

      final token = await AppInitializationController.resolveFcmToken(
        isWeb: true,
        skipForBackend: true,
        supportsMessaging: () async {
          supportChecks++;
          return true;
        },
        loadToken: () async {
          tokenLoads++;
          return 'unexpected';
        },
        subscribeToTopic: (_) async => subscriptions++,
      );

      expect(token, isEmpty);
      expect(supportChecks, 0);
      expect(tokenLoads, 0);
      expect(subscriptions, 0);
    });

    test('unsupported web browser never requests a token', () async {
      var tokenLoads = 0;

      final token = await AppInitializationController.resolveFcmToken(
        isWeb: true,
        skipForBackend: false,
        supportsMessaging: () async => false,
        loadToken: () async {
          tokenLoads++;
          return 'unexpected';
        },
        subscribeToTopic: (_) async {},
      );

      expect(token, isEmpty);
      expect(tokenLoads, 0);
    });

    test('web support probe failure is a safe no-op', () async {
      final token = await AppInitializationController.resolveFcmToken(
        isWeb: true,
        skipForBackend: false,
        supportsMessaging: () async => throw StateError('unsupported-browser'),
        loadToken: () async => 'unexpected',
        subscribeToTopic: (_) async {},
      );

      expect(token, isEmpty);
    });

    test('web token failure is a safe no-op after a positive probe', () async {
      final token = await AppInitializationController.resolveFcmToken(
        isWeb: true,
        skipForBackend: false,
        supportsMessaging: () async => true,
        loadToken: () async => throw StateError('notifications blocked'),
        subscribeToTopic: (_) async {},
      );

      expect(token, isEmpty);
    });

    test(
      'supported production web returns token without topic subscribe',
      () async {
        var subscriptions = 0;

        final token = await AppInitializationController.resolveFcmToken(
          isWeb: true,
          skipForBackend: false,
          supportsMessaging: () async => true,
          loadToken: () async => 'web-token',
          subscribeToTopic: (_) async => subscriptions++,
        );

        expect(token, 'web-token');
        expect(subscriptions, 0);
      },
    );

    test('native flow still loads token and subscribes to all-users', () async {
      var supportChecks = 0;
      String? subscribedTopic;

      final token = await AppInitializationController.resolveFcmToken(
        isWeb: false,
        skipForBackend: false,
        supportsMessaging: () async {
          supportChecks++;
          return false;
        },
        loadToken: () async => 'native-token',
        subscribeToTopic: (topic) async => subscribedTopic = topic,
      );

      expect(token, 'native-token');
      expect(supportChecks, 0);
      expect(subscribedTopic, 'allUsers');
    });

    test(
      'native token failures keep propagating to the existing handler',
      () async {
        await expectLater(
          AppInitializationController.resolveFcmToken(
            isWeb: false,
            skipForBackend: false,
            supportsMessaging: () async => true,
            loadToken: () async => throw StateError('native failure'),
            subscribeToTopic: (_) async {},
          ),
          throwsStateError,
        );
      },
    );
  });
}
