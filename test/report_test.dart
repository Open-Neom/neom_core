// Tests for `Report` — solo constructor + toJSON.
//
// El modelo no tiene fromJSON normal (solo fromDocumentSnapshot que
// requiere Firestore mocks).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/report.dart';
import 'package:neom_core/utils/enums/reference_type.dart';
import 'package:neom_core/utils/enums/report_type.dart';

void main() {
  group('Report — defaults', () {
    test('constructor sin params', () {
      final r = Report();
      expect(r.id, '');
      expect(r.ownerId, '');
      expect(r.type, ReportType.other);
      expect(r.referenceId, '');
      expect(r.referenceType, ReferenceType.post);
      expect(r.createdTime, 0);
      expect(r.modifiedTime, 0);
      expect(r.message, '');
      expect(r.processed, isFalse);
    });
  });

  group('Report — toJSON', () {
    test('contiene 8 llaves (NO incluye id)', () {
      final json = Report().toJSON();
      expect(json.containsKey('id'), isFalse);
      expect(json.length, 8);
      expect(
        json.keys,
        containsAll([
          'ownerId', 'type', 'referenceId', 'referenceType',
          'createdTime', 'modifiedTime', 'message', 'processed',
        ]),
      );
    });

    test('type y referenceType serializan como string (.name)', () {
      final r = Report(
        type: ReportType.other,
        referenceType: ReferenceType.post,
      );
      final json = r.toJSON();
      expect(json['type'], 'other');
      expect(json['referenceType'], 'post');
    });

    test('processed default false', () {
      expect(Report().toJSON()['processed'], isFalse);
    });
  });

  group('Report — toString', () {
    test('contiene los campos clave', () {
      final r = Report(
        id: 'r1', ownerId: 'u1', message: 'spam',
      );
      final s = r.toString();
      expect(s, contains('r1'));
      expect(s, contains('u1'));
      expect(s, contains('spam'));
    });
  });
}
