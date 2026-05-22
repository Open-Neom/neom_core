// Tests for `Booking` domain model.
//
// Foco: constructor con defaults, JSON round-trip de campos string/int,
// y manejo de `BookingStatus` (enum). El round-trip estricto del enum
// puede revelar inconsistencia entre toJSON (.name) y fromJSON (sin
// conversion). Si falla, lo registramos en docs/architecture_findings.md
// y se aborda más tarde.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/booking.dart';
import 'package:neom_core/utils/enums/booking_status.dart';

void main() {
  group('Booking — constructor', () {
    test('defaults razonables', () {
      final b = Booking();
      expect(b.id, '');
      expect(b.profileId, '');
      expect(b.profileName, '');
      expect(b.profileImgUrl, '');
      expect(b.placeId, '');
      expect(b.eventId, '');
      expect(b.date, 0);
      expect(b.bookingStatus, BookingStatus.notDefined);
      expect(b.orderId, '');
    });

    test('parámetros nombrados se asignan', () {
      final b = Booking(
        id: 'b1',
        profileId: 'u1',
        profileName: 'Juan',
        profileImgUrl: 'https://x/y.png',
        placeId: 'place1',
        eventId: 'event1',
        date: 1700000000000,
        bookingStatus: BookingStatus.notDefined,
        orderId: 'order1',
      );
      expect(b.id, 'b1');
      expect(b.profileId, 'u1');
      expect(b.profileName, 'Juan');
      expect(b.profileImgUrl, 'https://x/y.png');
      expect(b.placeId, 'place1');
      expect(b.eventId, 'event1');
      expect(b.date, 1700000000000);
      expect(b.bookingStatus, BookingStatus.notDefined);
      expect(b.orderId, 'order1');
    });
  });

  group('Booking — toJSON', () {
    test('contiene 9 llaves esperadas', () {
      final json = Booking().toJSON();
      expect(json.length, 9);
      expect(json.keys, containsAll([
        'id', 'profileId', 'profileName', 'profileImgUrl',
        'placeId', 'eventId', 'date', 'bookingStatus', 'orderId',
      ]));
    });

    test('bookingStatus se serializa como string (.name)', () {
      final b = Booking(bookingStatus: BookingStatus.notDefined);
      final json = b.toJSON();
      expect(json['bookingStatus'], isA<String>());
      expect(json['bookingStatus'], 'notDefined');
    });
  });

  group('Booking — fromJSON', () {
    test('mapa vacío produce booking con defaults', () {
      final b = Booking.fromJSON(<String, dynamic>{});
      expect(b.id, '');
      expect(b.profileId, '');
      expect(b.date, 0);
      expect(b.bookingStatus, BookingStatus.notDefined);
    });

    test('campos string básicos se restauran', () {
      final b = Booking.fromJSON({
        'id': 'b1',
        'profileId': 'u1',
        'placeId': 'p1',
        'eventId': 'e1',
        'date': 1700000000000,
        'orderId': 'o1',
      });
      expect(b.id, 'b1');
      expect(b.profileId, 'u1');
      expect(b.placeId, 'p1');
      expect(b.eventId, 'e1');
      expect(b.date, 1700000000000);
      expect(b.orderId, 'o1');
    });
  });

  group('Booking — round-trip estricto (puede revelar bug enum)', () {
    test('round-trip de campos string es lossless', () {
      final original = Booking(
        id: 'b1',
        profileId: 'u1',
        profileName: 'Juan',
        profileImgUrl: 'https://x',
        placeId: 'p1',
        eventId: 'e1',
        date: 1700000000000,
        orderId: 'o1',
      );
      final restored = Booking.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.profileId, original.profileId);
      expect(restored.profileName, original.profileName);
      expect(restored.profileImgUrl, original.profileImgUrl);
      expect(restored.placeId, original.placeId);
      expect(restored.eventId, original.eventId);
      expect(restored.date, original.date);
      expect(restored.orderId, original.orderId);
    });

    test('round-trip de bookingStatus debería ser lossless', () {
      // Posible bug en el modelo: toJSON serializa `.name` (String) pero
      // fromJSON asigna directamente `data["bookingStatus"]` sin convertir
      // string→enum. Si falla, queda registrado y se aborda como deuda.
      final original = Booking(bookingStatus: BookingStatus.notDefined);
      final restored = Booking.fromJSON(original.toJSON());
      expect(
        restored.bookingStatus,
        original.bookingStatus,
        reason: 'Si falla: toJSON usa .name (String), fromJSON no convierte de '
            'vuelta. Inconsistencia entre serialización y deserialización.',
      );
    });
  });
}
