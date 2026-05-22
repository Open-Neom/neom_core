// Tests for `AppInfo` domain model.
//
// AppInfo es el flag-bag de la app (versión, build, feature toggles).
// Es leído al boot, así que cualquier corrupción en su JSON apaga features
// silenciosamente. Tests cubren defaults, round-trip y orden de llaves.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_info.dart';

void main() {
  group('AppInfo — defaults del constructor', () {
    test('constructor sin parámetros tiene valores documentados', () {
      final info = AppInfo();
      expect(info.version, '');
      expect(info.build, 0);
      expect(info.googleLoginEnabled, isTrue,
          reason: 'login con Google está activo por defecto');
      expect(info.mediaPlayerEnabled, isTrue,
          reason: 'el reproductor está activo por defecto');
      expect(info.orderNumber, 1);
      expect(info.suggestedUrl, '');
      expect(info.hideNupale, isFalse);
      expect(info.hideCasete, isFalse);
      expect(info.hideWallet, isFalse);
      expect(info.maintenanceMode, isFalse,
          reason: 'la app NO arranca en modo mantenimiento por defecto');
      expect(info.releaseRevisionEnabled, isFalse);
      expect(info.demoReleaseEnabled, isFalse);
      expect(info.showAds, isFalse,
          reason: 'sin ads por defecto');
    });

    test('parámetros nombrados se asignan', () {
      final info = AppInfo(
        version: '3.0.0',
        build: 114,
        googleLoginEnabled: false,
        mediaPlayerEnabled: false,
        orderNumber: 2,
        suggestedUrl: 'https://x',
        maintenanceMode: true,
        showAds: true,
      );
      expect(info.version, '3.0.0');
      expect(info.build, 114);
      expect(info.googleLoginEnabled, isFalse);
      expect(info.mediaPlayerEnabled, isFalse);
      expect(info.orderNumber, 2);
      expect(info.suggestedUrl, 'https://x');
      expect(info.maintenanceMode, isTrue);
      expect(info.showAds, isTrue);
    });
  });

  group('AppInfo — toJSON', () {
    test('contiene 13 llaves esperadas', () {
      final json = AppInfo().toJSON();
      expect(json.length, 13);
      expect(
        json.keys,
        containsAll([
          'version', 'build', 'googleLoginEnabled', 'mediaPlayerEnabled',
          'suggestedUrl', 'orderNumber', 'hideNupale', 'hideCasete',
          'hideWallet', 'maintenanceMode', 'releaseRevisionEnabled',
          'demoReleaseEnabled', 'showAds',
        ]),
      );
    });

    test('valores booleanos se preservan como bool, no como string', () {
      final json = AppInfo(maintenanceMode: true).toJSON();
      expect(json['maintenanceMode'], isA<bool>());
      expect(json['maintenanceMode'], isTrue);
    });
  });

  group('AppInfo — round-trip', () {
    test('round-trip preserva todos los campos', () {
      final original = AppInfo(
        version: '3.0.0',
        build: 114,
        googleLoginEnabled: false,
        mediaPlayerEnabled: false,
        orderNumber: 99,
        suggestedUrl: 'https://upgrade.example/v3',
        hideNupale: true,
        hideCasete: true,
        hideWallet: true,
        maintenanceMode: true,
        releaseRevisionEnabled: true,
        demoReleaseEnabled: true,
        showAds: true,
      );

      final restored = AppInfo.fromJSON(original.toJSON());

      expect(restored.version, original.version);
      expect(restored.build, original.build);
      expect(restored.googleLoginEnabled, original.googleLoginEnabled);
      expect(restored.mediaPlayerEnabled, original.mediaPlayerEnabled);
      expect(restored.orderNumber, original.orderNumber);
      expect(restored.suggestedUrl, original.suggestedUrl);
      expect(restored.hideNupale, original.hideNupale);
      expect(restored.hideCasete, original.hideCasete);
      expect(restored.hideWallet, original.hideWallet);
      expect(restored.maintenanceMode, original.maintenanceMode);
      expect(restored.releaseRevisionEnabled, original.releaseRevisionEnabled);
      expect(restored.demoReleaseEnabled, original.demoReleaseEnabled);
      expect(restored.showAds, original.showAds);
    });

    test('fromJSON con mapa vacío usa defaults', () {
      final info = AppInfo.fromJSON(<String, dynamic>{});
      // Defaults documentados: googleLoginEnabled y mediaPlayerEnabled true,
      // orderNumber 1, todo lo demás false/0/"".
      expect(info.googleLoginEnabled, isTrue);
      expect(info.mediaPlayerEnabled, isTrue);
      expect(info.orderNumber, 1);
      expect(info.maintenanceMode, isFalse);
      expect(info.version, '');
      expect(info.build, 0);
    });

    test('fromJSON con campos null usa defaults', () {
      final info = AppInfo.fromJSON({
        'version': null,
        'build': null,
        'googleLoginEnabled': null,
        'maintenanceMode': null,
      });
      expect(info.version, '');
      expect(info.build, 0);
      expect(info.googleLoginEnabled, isTrue);
      expect(info.maintenanceMode, isFalse);
    });
  });

  group('AppInfo — flujos críticos', () {
    test('toggle de mantenimiento es lossless', () {
      final on = AppInfo(maintenanceMode: true);
      final off = AppInfo.fromJSON(on.toJSON());
      expect(off.maintenanceMode, isTrue);

      final off2 = AppInfo();
      final on2 = AppInfo.fromJSON(off2.toJSON());
      expect(on2.maintenanceMode, isFalse);
    });

    test('versionado usa string libre (semver, builds, sufijos)', () {
      for (final v in ['1.0.0', '3.0.0+114', '2.1.0-beta', '999.999.999']) {
        final info = AppInfo(version: v);
        expect(AppInfo.fromJSON(info.toJSON()).version, v);
      }
    });
  });
}
