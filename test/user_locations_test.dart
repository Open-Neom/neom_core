// Tests for `UserLocations`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/user_locations.dart';

void main() {
  group('UserLocations — defaults', () {
    test('constructor sin params', () {
      final u = UserLocations();
      expect(u.dateId, '');
      expect(u.totalUsers, 0);
      expect(u.totalLocations, 0);
      expect(u.locationCounts, isNull);
    });

    test('parámetros nombrados', () {
      final u = UserLocations(
        dateId: '2024-01-15',
        totalUsers: 1000,
        totalLocations: 50,
        locationCounts: {'CDMX': 500, 'GDL': 300},
      );
      expect(u.dateId, '2024-01-15');
      expect(u.totalUsers, 1000);
      expect(u.totalLocations, 50);
      expect(u.locationCounts, {'CDMX': 500, 'GDL': 300});
    });
  });

  group('UserLocations — fromJSON', () {
    test('parsea totalUsers y totalLocations + ubicaciones', () {
      final u = UserLocations.fromJSON({
        'totalUsers': 1000,
        'totalLocations': 50,
        'CDMX': 500,
        'GDL': 300,
      });
      expect(u.totalUsers, 1000);
      expect(u.totalLocations, 50);
      expect(u.locationCounts, {'CDMX': 500, 'GDL': 300});
    });

    test('parsea valores como strings', () {
      final u = UserLocations.fromJSON({
        'totalUsers': '500',
        'totalLocations': '25',
        'CDMX': '300',
      });
      expect(u.totalUsers, 500);
      expect(u.totalLocations, 25);
      expect(u.locationCounts, {'CDMX': 300});
    });

    test('valores no numéricos en ubicaciones se quedan en 0', () {
      final u = UserLocations.fromJSON({
        'totalUsers': 100,
        'totalLocations': 5,
        'CDMX': 'not_a_number',
      });
      expect(u.locationCounts!['CDMX'], 0);
    });

    test('mapa con solo totals (sin ubicaciones) tiene mapa vacío', () {
      final u = UserLocations.fromJSON({
        'totalUsers': 100,
        'totalLocations': 5,
      });
      expect(u.totalUsers, 100);
      expect(u.locationCounts, isEmpty);
    });
  });

  group('UserLocations — toJSON', () {
    test('serializa totalUsers/totalLocations como strings', () {
      final u = UserLocations(totalUsers: 100, totalLocations: 5);
      final json = u.toJSON();
      expect(json['totalUsers'], '100');
      expect(json['totalLocations'], '5');
    });

    test('serializa ubicaciones como strings', () {
      final u = UserLocations(
        totalUsers: 100, totalLocations: 5,
        locationCounts: {'CDMX': 500, 'GDL': 300},
      );
      final json = u.toJSON();
      expect(json['CDMX'], '500');
      expect(json['GDL'], '300');
    });

    test('locationCounts null no agrega llaves extra', () {
      final json = UserLocations(
        totalUsers: 1, totalLocations: 1,
      ).toJSON();
      expect(json.length, 2);
    });
  });
}
