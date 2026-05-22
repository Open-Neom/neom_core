// Tests for `Sponsor`.
//
// NC-44 esperado: line 97 `Address.fromJSON(data["address"])` sin `?? {}`.
// NC-44b esperado: profileId línea 93 `data["ownerId"]` (debería ser profileId).
// NC-44c esperado: line 101 `data["galleryImgUrls"].cast<String>()` con `.`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/sponsor.dart';
import 'package:neom_core/utils/enums/sponsor_type.dart';

void main() {
  group('Sponsor — defaults', () {
    test('constructor sin params', () {
      final s = Sponsor();
      expect(s.id, '');
      expect(s.name, '');
      expect(s.fullName, '');
      expect(s.phoneNumber, '');
      expect(s.countryCode, '');
      expect(s.description, '');
      expect(s.profileId, '');
      expect(s.imgUrl, '');
      expect(s.ownerId, '');
      expect(s.type, SponsorType.publicSpace);
      expect(s.address, isNull);
      expect(s.position, isNull);
      expect(s.isActive, isTrue);
      expect(s.externalUrl, '');
      expect(s.galleryImgUrls, isEmpty);
    });
  });

  group('Sponsor — toJSON', () {
    test('contiene 14 llaves', () {
      final json = Sponsor().toJSON();
      expect(json.length, 14);
      expect(
        json.keys,
        containsAll([
          'name', 'fullName', 'phoneNumber', 'countryCode',
          'description', 'ownerId', 'imgUrl', 'profileId',
          'type', 'address', 'position', 'isActive',
          'externalUrl', 'galleryImgUrls',
        ]),
      );
    });

    test('toJSONSimple omite ownerId, profileId, imgUrl', () {
      final json = Sponsor().toJSONSimple();
      expect(json.containsKey('ownerId'), isFalse);
      expect(json.containsKey('profileId'), isFalse);
      expect(json.containsKey('imgUrl'), isFalse);
    });
  });

  group('Sponsor.fromJSON (puede revelar NC-44/NC-44b/NC-44c)', () {
    test('NC-44b: profileId distinto de ownerId se preserva', () {
      // Bug: línea 93 hace `profileId = data["ownerId"]` en lugar de
      // `data["profileId"]`. Si los dos campos son distintos, profileId
      // se contamina con ownerId.
      final s = Sponsor.fromJSON({
        'name': 'Sponsor',
        'profileId': 'real_profile',
        'ownerId': 'admin_owner',
        'address': <String, dynamic>{},
        'galleryImgUrls': <String>[],
      });
      expect(
        s.profileId,
        'real_profile',
        reason: 'NC-44b: fromJSON línea 93 lee data["ownerId"] '
            'en lugar de data["profileId"]',
      );
      expect(s.ownerId, 'admin_owner');
    });

    test('NC-44: address null no debería crashear', () {
      try {
        final s = Sponsor.fromJSON({
          'name': 'X',
          'imgUrl': 'https://x',
          'address': null,
          'galleryImgUrls': <String>[],
        });
        expect(s.address, isNotNull);
      } on Object catch (e) {
        fail('NC-44: address null crashea Sponsor.fromJSON: $e');
      }
    });

    test('NC-44c: galleryImgUrls null no debería crashear', () {
      try {
        final s = Sponsor.fromJSON({
          'name': 'X',
          'imgUrl': 'https://x',
          'address': <String, dynamic>{},
          'galleryImgUrls': null,
        });
        expect(s.galleryImgUrls, isEmpty);
      } on NoSuchMethodError catch (e) {
        fail('NC-44c: cast directo `.cast<String>()` sobre null crashea: $e');
      }
    });

    test('round-trip de campos string básicos', () {
      final original = Sponsor(
        name: 'Sponsor',
        fullName: 'Sponsor Inc.',
        phoneNumber: '5551234',
        countryCode: '+52',
        description: 'desc',
        ownerId: 'admin',
        profileId: 'sp_profile',
        imgUrl: 'https://x',
        type: SponsorType.publicSpace,
        externalUrl: 'https://sponsor.com',
      );
      // Provee defaults explícitos para evitar crash.
      final json = {
        ...original.toJSON(),
        'address': <String, dynamic>{},
        'galleryImgUrls': <String>[],
      };
      final restored = Sponsor.fromJSON(json);
      expect(restored.name, original.name);
      expect(restored.fullName, original.fullName);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.description, original.description);
      expect(restored.ownerId, original.ownerId);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.type, original.type);
      expect(restored.externalUrl, original.externalUrl);
    });
  });
}
