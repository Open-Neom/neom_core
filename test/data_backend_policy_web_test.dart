import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data_backend_policy.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

void main() {
  Uri? resolve(String config, String location, {bool web = true}) =>
      DataBackendPolicy.resolveBaseUrl(
        config,
        isWeb: web,
        browserLocation: Uri.parse(location),
        allowedOrigins: const ['http://127.0.0.1:8787', 'https://gigmeout.io'],
      );

  test('hosted web uses the serving origin, including its port', () {
    expect(
      resolve('same-origin', 'http://127.0.0.1:8787/profile?x=1#tab'),
      Uri.parse('http://127.0.0.1:8787'),
    );
    expect(
      resolve('same-origin', 'https://gigmeout.io/catalog/song'),
      Uri.parse('https://gigmeout.io'),
    );
  });

  test('native same-origin stays unconfigured instead of using localhost', () {
    expect(resolve('same-origin', 'http://localhost:8787', web: false), isNull);
  });

  test('a web deployment outside the server allowlist keeps Firestore', () {
    expect(resolve('same-origin', 'https://gig-me-out.web.app'), isNull);
    expect(resolve('same-origin', 'http://127.0.0.1:9999'), isNull);
    expect(
      DataBackendPolicy.resolveBaseUrl(
        'same-origin',
        isWeb: true,
        browserLocation: Uri.parse('https://gigmeout.io'),
      ),
      isNull,
    );
  });

  test('invalid web origins and credential-bearing endpoints are rejected', () {
    for (final location in [
      'file:///app/index.html',
      'https://user:pass@host',
    ]) {
      expect(resolve('same-origin', location), isNull);
    }
    for (final config in [
      '',
      '/v1',
      'https://user:pass@host',
      'https://host?token=secret',
      'https://host#fragment',
      'ftp://host',
    ]) {
      expect(resolve(config, 'https://gigmeout.io'), isNull);
    }
  });

  test('explicit endpoint paths remain available for native and web', () {
    for (final web in [true, false]) {
      expect(
        resolve('https://data.example/api', 'https://gigmeout.io', web: web),
        Uri.parse('https://data.example/api'),
      );
    }
  });

  test('only enabled Gigmeout and Itzli can opt into data endpoints', () {
    for (final app in AppInUse.values) {
      final policy = DataBackendPolicy.fromProperties(app, {
        'dataBackend': {'enabled': true, 'baseUrl': 'https://data.example'},
      });
      expect(policy.hasServer, app == AppInUse.g || app == AppInUse.i);
    }
  });
}
