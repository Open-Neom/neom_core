// Tests for `Review`.
//
// Foco: defaults, round-trip JSON, y un OBS sobre la inconsistencia entre
// la llave de toJSON ('reviewerProfile') y el field name (reviewerProfileId).
// El round-trip funciona porque fromJSON lee la misma llave.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/review.dart';

void main() {
  group('Review — defaults', () {
    test('constructor sin params', () {
      final r = Review();
      expect(r.id, '');
      expect(r.text, '');
      expect(r.ratingValue, 0);
      expect(r.createdDate, 0);
      expect(r.reviewerProfileId, '');
      expect(r.reviewerName, '');
      expect(r.reviewerTitle, '');
      expect(r.profileImgUrl, '');
      expect(r.recommend, isTrue,
          reason: 'constructor default recommend=true');
    });

    test('parámetros nombrados', () {
      final r = Review(
        id: 'r1',
        text: '¡Excelente!',
        ratingValue: 5,
        createdDate: 1700000000000,
        reviewerProfileId: 'u1',
        reviewerName: 'Ana',
        reviewerTitle: 'Productora',
        profileImgUrl: 'https://x',
        recommend: false,
      );
      expect(r.id, 'r1');
      expect(r.text, '¡Excelente!');
      expect(r.ratingValue, 5);
      expect(r.createdDate, 1700000000000);
      expect(r.reviewerProfileId, 'u1');
      expect(r.reviewerName, 'Ana');
      expect(r.reviewerTitle, 'Productora');
      expect(r.profileImgUrl, 'https://x');
      expect(r.recommend, isFalse);
    });
  });

  group('Review — toJSON', () {
    test('contiene 9 llaves', () {
      final json = Review().toJSON();
      expect(json.length, 9);
      expect(
        json.keys,
        containsAll([
          'id', 'text', 'ratingValue', 'createdDate',
          'reviewerProfile', 'reviewerName', 'reviewerTitle',
          'profileImgUrl', 'recommend',
        ]),
      );
    });

    test('OBS: la llave en JSON es "reviewerProfile" no "reviewerProfileId"', () {
      // El field es reviewerProfileId pero la llave persistida es reviewerProfile.
      // Es deuda visual; el round-trip funciona porque fromJSON usa la misma.
      final json = Review(reviewerProfileId: 'u1').toJSON();
      expect(json['reviewerProfile'], 'u1');
      expect(json.containsKey('reviewerProfileId'), isFalse);
    });
  });

  group('Review — fromJSON', () {
    test('round-trip preserva campos', () {
      final original = Review(
        id: 'r1',
        text: 'review',
        ratingValue: 4,
        createdDate: 1700000000000,
        reviewerProfileId: 'u1',
        reviewerName: 'Ana',
        reviewerTitle: 'Pro',
        profileImgUrl: 'https://x',
        recommend: true,
      );
      final restored = Review.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.ratingValue, original.ratingValue);
      expect(restored.createdDate, original.createdDate);
      expect(restored.reviewerProfileId, original.reviewerProfileId);
      expect(restored.reviewerName, original.reviewerName);
      expect(restored.reviewerTitle, original.reviewerTitle);
      expect(restored.profileImgUrl, original.profileImgUrl);
      expect(restored.recommend, original.recommend);
    });

    test('OBS: default `recommend` en fromJSON difiere del constructor', () {
      // Constructor → recommend=true. fromJSON → recommend=false.
      // Documentado para evitar que un cambio futuro inadvertido rompa
      // la simetría sin que el equipo lo note.
      final r = Review.fromJSON(<String, dynamic>{});
      expect(r.recommend, isFalse,
          reason: 'fromJSON default `?? false` (constructor default es true)');
    });

    test('mapa vacío con campos básicos cae a defaults', () {
      final r = Review.fromJSON(<String, dynamic>{});
      expect(r.id, '');
      expect(r.ratingValue, 0);
      expect(r.createdDate, 0);
    });
  });
}
