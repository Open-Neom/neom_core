// Tests for `Event` — eventos (concierto, sesión, ensayo, evento online).
//
// Revela bug NC-12: toJSON serializa `watchingProfiles: []` y
// `goingProfiles: []` como **listas vacías hardcodeadas**, ignorando los
// valores reales. Round-trip pierde la lista de asistentes.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/utils/enums/event_status.dart';
import 'package:neom_core/utils/enums/event_type.dart';
import 'package:neom_core/utils/enums/usage_reason.dart';

void main() {
  group('Event — defaults', () {
    test('constructor sin params', () {
      final e = Event();
      expect(e.id, '');
      expect(e.name, '');
      expect(e.description, '');
      expect(e.imgUrl, '');
      expect(e.coverImgUrl, '');
      expect(e.public, isTrue);
      expect(e.createdTime, 0);
      expect(e.eventDate, 0);
      expect(e.reason, UsageReason.any);
      expect(e.itemPercentageCoverage, 0.0);
      expect(e.distanceKm, 0);
      expect(e.type, EventType.rehearsal);
      expect(e.status, EventStatus.draft);
      expect(e.isFulfilled, isFalse);
      expect(e.isOnline, isFalse);
      expect(e.isOutdoor, isFalse);
      expect(e.isTest, isFalse);
      expect(e.guestsLimit, 0);
      expect(e.isEdited, isFalse);
      expect(e.slug, '');
      expect(e.isRecurring, isFalse);
      expect(e.recurringDays, isEmpty);
      expect(e.recurringTime, '');
      expect(e.roomId, '');
      expect(e.googleCalendarId, '');
    });
  });

  group('Event.createBasic', () {
    test('factory con name y description mínimos', () {
      final e = Event.createBasic('Concierto', 'Descripción');
      expect(e.name, 'Concierto');
      expect(e.description, 'Descripción');
      expect(e.public, isTrue);
      expect(e.type, EventType.rehearsal);
      expect(e.status, EventStatus.draft);
    });
  });

  group('Event.generateSlug', () {
    test('título simple', () {
      expect(Event.generateSlug('Concierto en vivo'), 'concierto-en-vivo');
    });

    test('preserva acentos', () {
      expect(Event.generateSlug('Año nuevo'), 'año-nuevo');
    });

    test('elimina símbolos', () {
      expect(Event.generateSlug('¡Concierto!'), 'concierto');
    });
  });

  group('Event — toJSON básico', () {
    test('serializa type, status, reason como string (.name)', () {
      final json = Event(
        type: EventType.rehearsal,
        status: EventStatus.draft,
        reason: UsageReason.any,
      ).toJSON();
      expect(json['type'], 'rehearsal');
      expect(json['status'], 'draft');
      expect(json['reason'], 'any');
    });
  });

  group('Event — round-trip básico', () {
    test('campos string + bool + ints se preservan', () {
      final original = Event(
        id: 'e1',
        name: 'Concierto',
        description: 'desc',
        imgUrl: 'https://x',
        coverImgUrl: 'https://cover',
        ownerId: 'u1',
        ownerName: 'Ana',
        ownerEmail: 'a@x.com',
        public: false,
        createdTime: 1700000000000,
        eventDate: 1700100000000,
        reason: UsageReason.any,
        itemPercentageCoverage: 75.5,
        distanceKm: 10,
        type: EventType.rehearsal,
        status: EventStatus.draft,
        isFulfilled: true,
        isOnline: true,
        isOutdoor: false,
        isTest: false,
        guestsLimit: 100,
        isEdited: true,
        slug: 'concierto',
        isRecurring: true,
        recurringDays: [1, 3, 5],
        recurringTime: '20:00',
        roomId: 'room1',
        googleCalendarId: 'gcal1',
      );
      final restored = Event.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.coverImgUrl, original.coverImgUrl);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.public, original.public);
      expect(restored.createdTime, original.createdTime);
      expect(restored.eventDate, original.eventDate);
      expect(restored.reason, original.reason);
      expect(restored.itemPercentageCoverage, original.itemPercentageCoverage);
      expect(restored.distanceKm, original.distanceKm);
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.isFulfilled, original.isFulfilled);
      expect(restored.isOnline, original.isOnline);
      expect(restored.isOutdoor, original.isOutdoor);
      expect(restored.isTest, original.isTest);
      expect(restored.guestsLimit, original.guestsLimit);
      expect(restored.isEdited, original.isEdited);
      expect(restored.slug, original.slug);
      expect(restored.isRecurring, original.isRecurring);
      expect(restored.recurringDays, original.recurringDays);
      expect(restored.recurringTime, original.recurringTime);
      expect(restored.roomId, original.roomId);
      expect(restored.googleCalendarId, original.googleCalendarId);
    });
  });

  group('Event — round-trip de listas (puede revelar NC-12)', () {
    test('NC-12: watchingProfiles debería preservarse tras round-trip', () {
      // Bug: toJSON hardcodea `watchingProfiles: []`. Resultado: listas
      // de espectadores se borran en cada save.
      final original = Event(
        watchingProfiles: ['u1', 'u2', 'u3'],
      );
      final restored = Event.fromJSON(original.toJSON());
      expect(
        restored.watchingProfiles,
        original.watchingProfiles,
        reason: 'NC-12: Event.toJSON serializa watchingProfiles como [] '
            'hardcodeado, perdiendo los IDs reales del modelo.',
      );
    });

    test('NC-12: goingProfiles debería preservarse tras round-trip', () {
      final original = Event(
        goingProfiles: ['u1', 'u2'],
      );
      final restored = Event.fromJSON(original.toJSON());
      expect(
        restored.goingProfiles,
        original.goingProfiles,
        reason: 'NC-12: Event.toJSON serializa goingProfiles como [] '
            'hardcodeado, perdiendo los IDs.',
      );
    });

    test('genres se preservan tras round-trip', () {
      final original = Event(genres: ['rock', 'jazz']);
      final restored = Event.fromJSON(original.toJSON());
      expect(restored.genres, ['rock', 'jazz']);
    });
  });

  group('Event — fromJSON con datos legacy/parciales', () {
    test('mapa vacío usa defaults', () {
      final e = Event.fromJSON(<String, dynamic>{});
      expect(e.id, '');
      expect(e.public, isTrue);
      expect(e.type, EventType.rehearsal);
      expect(e.status, EventStatus.draft);
    });

    test('campos null usan defaults', () {
      final e = Event.fromJSON({
        'name': null,
        'public': null,
        'isFulfilled': null,
      });
      expect(e.name, '');
      expect(e.public, isTrue);
      expect(e.isFulfilled, isFalse);
    });
  });
}
