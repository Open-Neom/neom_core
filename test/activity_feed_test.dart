// Tests for `ActivityFeed` — feed de actividad/notificaciones.
//
// Foco: constructor por defecto, round-trip de campos persistidos,
// toJSON vs toJSONWithId. Los factory constructors (fromEvent, fromPost,
// fromComment, etc.) requieren modelos pesados y se cubren más adelante.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/utils/enums/activity_feed_type.dart';

void main() {
  group('ActivityFeed — defaults', () {
    test('constructor sin params', () {
      final f = ActivityFeed();
      expect(f.id, '');
      expect(f.ownerId, '');
      expect(f.profileId, '');
      expect(f.profileName, '');
      expect(f.profileImgUrl, '');
      expect(f.message, '');
      expect(f.activityReferenceId, '');
      expect(f.activityFeedType, isNull);
      expect(f.mediaUrl, '');
      expect(f.createdTime, 0);
      expect(f.unread, isTrue,
          reason: 'feed nuevo arranca como no-leído (por diseño)');
    });

    test('parámetros nombrados se asignan', () {
      final f = ActivityFeed(
        id: 'f1',
        ownerId: 'owner',
        profileId: 'sender',
        profileName: 'Ana',
        profileImgUrl: 'https://x',
        message: 'mensaje',
        activityReferenceId: 'ref1',
        activityFeedType: ActivityFeedType.comment,
        mediaUrl: 'https://media',
        createdTime: 1700000000000,
        unread: false,
      );
      expect(f.id, 'f1');
      expect(f.ownerId, 'owner');
      expect(f.profileId, 'sender');
      expect(f.activityFeedType, ActivityFeedType.comment);
      expect(f.unread, isFalse);
    });
  });

  group('ActivityFeed — toJSON', () {
    test('toJSON NO incluye id (Firebase docId)', () {
      final f = ActivityFeed(id: 'f1');
      expect(f.toJSON().containsKey('id'), isFalse);
    });

    test('toJSONWithId SÍ incluye id', () {
      final f = ActivityFeed(id: 'f1');
      expect(f.toJSONWithId().containsKey('id'), isTrue);
      expect(f.toJSONWithId()['id'], 'f1');
    });

    test('activityFeedType serializa como string (.name)', () {
      final f = ActivityFeed(activityFeedType: ActivityFeedType.comment);
      expect(f.toJSON()['activityFeedType'], 'comment');
    });

    test('activityFeedType null serializa como cadena vacía', () {
      final f = ActivityFeed();
      expect(f.toJSON()['activityFeedType'], '');
    });

    test('toJSON y toJSONWithId coinciden salvo en id', () {
      final f = ActivityFeed(
        id: 'f1',
        ownerId: 'o',
        message: 'm',
      );
      final basic = f.toJSON();
      final withId = f.toJSONWithId();

      // toJSONWithId tiene una llave más
      expect(withId.length, basic.length + 1);
      // Los demás campos coinciden
      for (final key in basic.keys) {
        expect(withId[key], basic[key], reason: 'mismatch en $key');
      }
    });
  });

  group('ActivityFeed — fromJSON', () {
    test('round-trip preserva campos', () {
      final original = ActivityFeed(
        id: 'f1',
        ownerId: 'owner',
        profileId: 'sender',
        profileName: 'Ana',
        profileImgUrl: 'https://x',
        message: 'mensaje',
        activityReferenceId: 'ref1',
        activityFeedType: ActivityFeedType.comment,
        mediaUrl: 'https://media',
        createdTime: 1700000000000,
        unread: false,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = ActivityFeed.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.ownerId, original.ownerId);
      expect(restored.profileId, original.profileId);
      expect(restored.profileName, original.profileName);
      expect(restored.profileImgUrl, original.profileImgUrl);
      expect(restored.message, original.message);
      expect(restored.activityReferenceId, original.activityReferenceId);
      expect(restored.activityFeedType, original.activityFeedType);
      expect(restored.mediaUrl, original.mediaUrl);
      expect(restored.createdTime, original.createdTime);
      expect(restored.unread, original.unread);
    });

    test('mapa vacío usa defaults (unread true por diseño)', () {
      final f = ActivityFeed.fromJSON(<String, dynamic>{});
      expect(f.id, '');
      expect(f.ownerId, '');
      expect(f.unread, isTrue);
    });

    test('activityFeedType con string desconocido devuelve null', () {
      final f = ActivityFeed.fromJSON({'activityFeedType': 'unknownType'});
      expect(f.activityFeedType, isNull);
    });

    test('activityFeedType con cadena vacía cae al fallback comment', () {
      // El código hace `data["activityFeedType"] ?? ActivityFeedType.comment.name`
      // si la llave está ausente. Cuando viene "" string, EnumToString.fromString
      // devuelve null porque "" no matchea ningún valor.
      final f = ActivityFeed.fromJSON({'activityFeedType': ''});
      expect(f.activityFeedType, isNull,
          reason: 'cadena vacía no matchea — devuelve null');
    });
  });
}
