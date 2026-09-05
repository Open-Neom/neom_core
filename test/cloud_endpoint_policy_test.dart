import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/cloud_endpoint_policy.dart';
import 'package:neom_core/cloud_properties.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

void main() {
  const productionUrl =
      'https://us-central1-emxi-9c5b5.cloudfunctions.net/pdfProxy';

  group('CloudEndpointPolicy', () {
    test('uses Functions emulator for a non-release build', () {
      final url = CloudEndpointPolicy.resolveFunctionUrl(
        functionName: 'pdfProxy',
        productionUrl: productionUrl,
        isRelease: false,
        usesEmulators: true,
      );

      expect(url, 'http://127.0.0.1:5001/demo-emxi-local/us-central1/pdfProxy');
      expect(url, isNot(contains('emxi-9c5b5')));
    });

    test('preserves the production URL for a release build', () {
      final url = CloudEndpointPolicy.resolveFunctionUrl(
        functionName: 'pdfProxy',
        productionUrl: productionUrl,
        isRelease: true,
        usesEmulators: false,
      );

      expect(url, productionUrl);
    });

    test('blocks production fallback in debug/profile', () {
      expect(
        () => CloudEndpointPolicy.resolveFunctionUrl(
          functionName: 'secureOpsWeb',
          productionUrl: 'https://secureops.example.run.app',
          isRelease: false,
          usesEmulators: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('honors explicit local emulator coordinates', () {
      final url = CloudEndpointPolicy.resolveFunctionUrl(
        functionName: 'secureOpsWeb',
        productionUrl: 'https://secureops.example.run.app',
        isRelease: false,
        usesEmulators: true,
        host: '10.0.2.2',
        port: 5500,
        projectId: 'demo-custom',
        region: 'northamerica-northeast1',
      );

      expect(
        url,
        'http://10.0.2.2:5500/demo-custom/northamerica-northeast1/'
        'secureOpsWeb',
      );
    });

    test('CloudProperties applies the guard to both direct HTTP endpoints', () {
      CloudProperties.appInUse = AppInUse.e;

      expect(
        CloudProperties.getPdfProxyUrl(),
        'http://127.0.0.1:5001/demo-emxi-local/us-central1/pdfProxy',
      );
      expect(
        CloudProperties.getSecureOpsWebUrl(),
        'http://127.0.0.1:5001/demo-emxi-local/us-central1/secureOpsWeb',
      );
    });
  });
}
