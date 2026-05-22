// Tests for `AppProfile` — modelo de perfil del usuario (cada user puede
// tener varios profiles). Modelo grande (416 LOC, 50+ campos) — tests
// focalizados en defaults, generateSlug, round-trip de campos top-level.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/usage_reason.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

void main() {
  group('AppProfile — defaults', () {
    test('constructor sin params', () {
      final p = AppProfile();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.aboutMe, '');
      expect(p.photoUrl, '');
      expect(p.coverImgUrl, '');
      expect(p.mainFeature, '');
      expect(p.lastTimeOn, 0);
      expect(p.isActive, isFalse);
      expect(p.address, '');
      expect(p.phoneNumber, '');
      expect(p.type, ProfileType.general);
      expect(p.usageReason, UsageReason.casual);
      expect(p.reviewStars, 10.0);
      expect(p.directoryVisible, isTrue);
      expect(p.showPhone, isTrue);
      expect(p.portfolioUrl, '');
      expect(p.totalTipsReceived, 0);
      expect(p.verificationLevel, VerificationLevel.none);
      expect(p.lastNameUpdate, 0);
      expect(p.slug, '');
    });
  });

  group('AppProfile.generateSlug', () {
    test('quita espacios y minúsculas', () {
      expect(AppProfile.generateSlug('Serzen Montoya'), 'serzenmontoya');
    });

    test('preserva acentos y ñ', () {
      expect(AppProfile.generateSlug('Niño Año'), 'niñoaño');
    });

    test('elimina caracteres especiales', () {
      expect(AppProfile.generateSlug('Juan!@#Pérez'), 'juanpérez');
    });

    test('cadena vacía produce slug vacío', () {
      expect(AppProfile.generateSlug(''), '');
    });

    test('solo símbolos produce slug vacío', () {
      expect(AppProfile.generateSlug('!@#\$%'), '');
    });
  });

  group('AppProfile — toJSON básico', () {
    test('serializa type, usageReason, verificationLevel como strings', () {
      final p = AppProfile(
        type: ProfileType.appArtist,
        usageReason: UsageReason.casual,
        verificationLevel: VerificationLevel.none,
      );
      final json = p.toJSON();
      expect(json['type'], 'appArtist');
      expect(json['usageReason'], 'casual');
      expect(json['verificationLevel'], 'none');
    });
  });

  group('AppProfile — round-trip básico', () {
    test('campos string + bool + int se preservan', () {
      final original = AppProfile(
        id: 'p1',
        name: 'Ana',
        photoUrl: 'https://x',
        coverImgUrl: 'https://cover',
        aboutMe: 'about',
        mainFeature: 'mf',
        address: 'CDMX',
        phoneNumber: '+5215551234',
        type: ProfileType.appArtist,
        usageReason: UsageReason.casual,
        reviewStars: 4.5,
        isActive: true,
        directoryVisible: false,
        showPhone: false,
        portfolioUrl: 'https://port',
        totalTipsReceived: 500,
        verificationLevel: VerificationLevel.none,
        lastNameUpdate: 1700000000000,
        slug: 'ana',
      );
      final restored = AppProfile.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.coverImgUrl, original.coverImgUrl);
      expect(restored.aboutMe, original.aboutMe);
      expect(restored.mainFeature, original.mainFeature);
      expect(restored.address, original.address);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.type, original.type);
      expect(restored.usageReason, original.usageReason);
      expect(restored.reviewStars, original.reviewStars);
      expect(restored.isActive, original.isActive);
      expect(restored.directoryVisible, original.directoryVisible);
      expect(restored.showPhone, original.showPhone);
      expect(restored.portfolioUrl, original.portfolioUrl);
      expect(restored.totalTipsReceived, original.totalTipsReceived);
      expect(restored.verificationLevel, original.verificationLevel);
      expect(restored.lastNameUpdate, original.lastNameUpdate);
      expect(restored.slug, original.slug);
    });

    test('listas se preservan tras round-trip', () {
      final original = AppProfile(
        followers: ['f1', 'f2'],
        following: ['fol1'],
        favoriteItems: ['item1'],
        watchingEvents: ['e1'],
        goingEvents: ['e2'],
      );
      final restored = AppProfile.fromJSON(original.toJSON());
      expect(restored.followers, ['f1', 'f2']);
      expect(restored.following, ['fol1']);
      expect(restored.favoriteItems, ['item1']);
      expect(restored.watchingEvents, ['e1']);
      expect(restored.goingEvents, ['e2']);
    });

    test('mapa vacío usa defaults', () {
      final p = AppProfile.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.type, ProfileType.general);
      expect(p.usageReason, UsageReason.casual);
      expect(p.verificationLevel, VerificationLevel.none);
      expect(p.directoryVisible, isTrue);
      expect(p.showPhone, isTrue);
      expect(p.totalTipsReceived, 0);
    });

    test('listas null se hidratan como vacías', () {
      final p = AppProfile.fromJSON({
        'followers': null,
        'goingEvents': null,
        'badges': null,
      });
      expect(p.followers, isEmpty);
      expect(p.goingEvents, isEmpty);
      expect(p.badges, isEmpty);
    });

    test('OBS: isActive default fromJSON=true, constructor=false', () {
      // Inconsistencia documentada (no es bug crítico, pero conviene saber).
      final fromEmpty = AppProfile.fromJSON(<String, dynamic>{});
      expect(fromEmpty.isActive, isTrue,
          reason: 'fromJSON usa `?? true` mientras el constructor default es false');
    });
  });

  group('AppProfile — campos opcionales', () {
    test('influences null se hidrata como lista vacía', () {
      final p = AppProfile.fromJSON({'influences': null});
      expect(p.influences, isEmpty);
    });

    test('giglists/facilities/skills null se hidratan como mapa vacío', () {
      final p = AppProfile.fromJSON({
        'giglists': null,
        'facilities': null,
        'skills': null,
      });
      expect(p.giglists, isEmpty);
      expect(p.facilities, isEmpty);
      expect(p.skills, isEmpty);
    });
  });
}
