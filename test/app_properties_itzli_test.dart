import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_properties.dart';

void main() {
  tearDown(() {
    AppProperties.appProperties = {};
  });

  group('AppProperties.isItzliEnabled', () {
    test('defaults to true when flag is not present', () {
      AppProperties.appProperties = {};
      expect(AppProperties.isItzliEnabled(), isTrue);
    });

    test('returns false when isItzliEnabled is false (boolean)', () {
      AppProperties.appProperties = {'isItzliEnabled': false};
      expect(AppProperties.isItzliEnabled(), isFalse);
    });

    test('returns false when isItzliEnabled is "false" (string)', () {
      AppProperties.appProperties = {'isItzliEnabled': 'false'};
      expect(AppProperties.isItzliEnabled(), isFalse);
    });

    test('returns true when isItzliEnabled is true (boolean)', () {
      AppProperties.appProperties = {'isItzliEnabled': true};
      expect(AppProperties.isItzliEnabled(), isTrue);
    });

    test('returns true when isItzliEnabled is "true" (string)', () {
      AppProperties.appProperties = {'isItzliEnabled': 'true'};
      expect(AppProperties.isItzliEnabled(), isTrue);
    });

    test('falls back to isSaiaEnabled when isItzliEnabled is absent', () {
      AppProperties.appProperties = {'isSaiaEnabled': false};
      expect(AppProperties.isItzliEnabled(), isFalse);

      AppProperties.appProperties = {'isSaiaEnabled': true};
      expect(AppProperties.isItzliEnabled(), isTrue);
    });
  });
}
