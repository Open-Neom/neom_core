// Tests for `AppRequest` — solicitudes (game, DAW, release approval, etc.).
//
// Cubre defaults, computed properties (isExpired/isPending/isGameRequest/
// isReleaseApprovalRequest/isDawInvitation/timeRemaining), factory
// constructors, copyWith, JSON round-trip. Revela posibles bugs en
// fromJSON (id no se carga, unread default String).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_request.dart';
import 'package:neom_core/utils/enums/game_request_type.dart';
import 'package:neom_core/utils/enums/request_decision.dart';

void main() {
  group('AppRequest — defaults', () {
    test('constructor sin params', () {
      final r = AppRequest();
      expect(r.id, '');
      expect(r.from, '');
      expect(r.to, '');
      expect(r.collectiveId, '');
      expect(r.eventId, '');
      expect(r.positionRequestedId, '');
      expect(r.createdTime, 0);
      expect(r.expiresAt, 0);
      expect(r.newOffer, isNull);
      expect(r.message, '');
      expect(r.unread, isTrue);
      expect(r.instrument, isNull);
      expect(r.percentageCoverage, 0);
      expect(r.distanceKm, 0);
      expect(r.requestDecision, RequestDecision.pending);
      expect(r.gameRequestType, isNull);
    });
  });

  group('AppRequest — computed properties', () {
    test('isExpired: false cuando expiresAt == 0', () {
      final r = AppRequest(expiresAt: 0);
      expect(r.isExpired, isFalse);
    });

    test('isExpired: true cuando expiresAt en el pasado', () {
      final r = AppRequest(expiresAt: 1);
      expect(r.isExpired, isTrue);
    });

    test('isExpired: false cuando expiresAt en el futuro', () {
      final far = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      expect(AppRequest(expiresAt: far).isExpired, isFalse);
    });

    test('isPending: true cuando pending y no expirado', () {
      final far = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final r = AppRequest(
        requestDecision: RequestDecision.pending,
        expiresAt: far,
      );
      expect(r.isPending, isTrue);
    });

    test('isPending: false si expirado', () {
      final r = AppRequest(
        requestDecision: RequestDecision.pending,
        expiresAt: 1,
      );
      expect(r.isPending, isFalse);
    });

    test('isPending: false si decisión != pending', () {
      final far = DateTime.now()
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final r = AppRequest(
        requestDecision: RequestDecision.confirmed,
        expiresAt: far,
      );
      expect(r.isPending, isFalse);
    });

    test('timeRemaining: zero cuando expiresAt == 0', () {
      expect(AppRequest(expiresAt: 0).timeRemaining, Duration.zero);
    });

    test('timeRemaining: zero cuando ya expirado', () {
      expect(AppRequest(expiresAt: 1).timeRemaining, Duration.zero);
    });

    test('timeRemaining: positivo cuando expira en el futuro', () {
      final far = DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      final remaining = AppRequest(expiresAt: far).timeRemaining;
      expect(remaining.inSeconds, greaterThan(0));
      expect(remaining.inMinutes, lessThanOrEqualTo(5));
    });

    test('isGameRequest: true cuando gameRequestType != null', () {
      final r = AppRequest(gameRequestType: GameRequestType.values.first);
      expect(r.isGameRequest, isTrue);
    });

    test('isGameRequest: false cuando gameRequestType == null', () {
      expect(AppRequest().isGameRequest, isFalse);
    });

    test('isReleaseApprovalRequest: requiere id con _release_ + eventId no vacío', () {
      final r = AppRequest(id: 'abc_release_123', eventId: 'rel1');
      expect(r.isReleaseApprovalRequest, isTrue);
    });

    test('isReleaseApprovalRequest: false sin "_release_" en id', () {
      final r = AppRequest(id: 'normal', eventId: 'rel1');
      expect(r.isReleaseApprovalRequest, isFalse);
    });

    test('isReleaseApprovalRequest: false si es game request', () {
      final r = AppRequest(
        id: 'abc_release_123',
        eventId: 'rel1',
        gameRequestType: GameRequestType.values.first,
      );
      expect(r.isReleaseApprovalRequest, isFalse);
    });

    test('isDawInvitation: requiere "_daw_" en id + eventId', () {
      final r = AppRequest(id: 'u1_daw_42', eventId: 'proj1');
      expect(r.isDawInvitation, isTrue);
    });

    test('isDawInvitation: false si game request', () {
      final r = AppRequest(
        id: 'u1_daw_42',
        eventId: 'proj1',
        gameRequestType: GameRequestType.values.first,
      );
      expect(r.isDawInvitation, isFalse);
    });
  });

  group('AppRequest — factory gameInvitation', () {
    test('genera id, eventId y expiresAt correctamente', () {
      final r = AppRequest.gameInvitation(
        from: 'u1',
        to: 'u2',
        gameType: GameRequestType.values.first,
      );
      expect(r.from, 'u1');
      expect(r.to, 'u2');
      expect(r.id, contains('u1_u2_'));
      expect(r.eventId, contains('u1_'));
      expect(r.eventId, contains('_u2_'));
      expect(r.expiresAt, greaterThan(r.createdTime));
      expect(r.requestDecision, RequestDecision.pending);
      expect(r.isGameRequest, isTrue);
    });

    test('expirationMinutes default es 3 minutos', () {
      final r = AppRequest.gameInvitation(
        from: 'u1',
        to: 'u2',
        gameType: GameRequestType.values.first,
      );
      final delta = r.expiresAt - r.createdTime;
      expect(delta, AppRequest.defaultGameExpirationMinutes * 60 * 1000);
    });

    test('expirationMinutes custom respeta el valor', () {
      final r = AppRequest.gameInvitation(
        from: 'u1',
        to: 'u2',
        gameType: GameRequestType.values.first,
        expirationMinutes: 10,
      );
      final delta = r.expiresAt - r.createdTime;
      expect(delta, 10 * 60 * 1000);
    });
  });

  group('AppRequest — factory dawInvitation', () {
    test('genera id con _daw_ y eventId == projectId', () {
      final r = AppRequest.dawInvitation(
        from: 'u1',
        to: 'u2',
        projectId: 'proj1',
        projectName: 'My Project',
      );
      expect(r.id, contains('_daw_'));
      expect(r.eventId, 'proj1');
      expect(r.message, contains('My Project'));
      expect(r.message, contains('musician'));
      expect(r.isDawInvitation, isTrue);
    });

    test('expira en 7 días por default', () {
      final r = AppRequest.dawInvitation(
        from: 'u1', to: 'u2', projectId: 'p', projectName: 'n',
      );
      final delta = r.expiresAt - r.createdTime;
      expect(delta, AppRequest.defaultDawExpirationDays * 24 * 60 * 60 * 1000);
    });

    test('role custom aparece en el mensaje', () {
      final r = AppRequest.dawInvitation(
        from: 'u1', to: 'u2', projectId: 'p', projectName: 'n',
        role: 'producer',
      );
      expect(r.message, contains('producer'));
    });
  });

  group('AppRequest — factory releaseApproval', () {
    test('genera id con _release_', () {
      final r = AppRequest.releaseApproval(
        from: 'u1',
        to: 'EMXI',
        releaseItemId: 'rel1',
        releaseName: 'Mi álbum',
      );
      expect(r.id, contains('_release_'));
      expect(r.eventId, 'rel1');
      expect(r.message, contains('Mi álbum'));
      expect(r.isReleaseApprovalRequest, isTrue);
    });

    test('mensaje incluye author cuando se provee', () {
      final r = AppRequest.releaseApproval(
        from: 'u1',
        to: 'EMXI',
        releaseItemId: 'rel1',
        releaseName: 'Album',
        authorName: 'Ana',
      );
      expect(r.message, contains('Ana'));
    });
  });

  group('AppRequest.copyWith', () {
    test('sin overrides devuelve copia idéntica en valores', () {
      final original = AppRequest(
        id: 'r1', from: 'u1', to: 'u2', message: 'hi',
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.from, original.from);
      expect(copy.to, original.to);
      expect(copy.message, original.message);
    });

    test('overrides cambian solo los campos especificados', () {
      final original = AppRequest(from: 'u1', to: 'u2', message: 'hi');
      final copy = original.copyWith(message: 'edited');
      expect(copy.from, 'u1');
      expect(copy.to, 'u2');
      expect(copy.message, 'edited');
    });
  });

  group('AppRequest — toJSON', () {
    test('serializa requestDecision como string', () {
      final r = AppRequest(requestDecision: RequestDecision.confirmed);
      expect(r.toJSON()['requestDecision'], 'confirmed');
    });

    test('gameRequestType null serializa como null', () {
      expect(AppRequest().toJSON()['gameRequestType'], isNull);
    });
  });

  group('AppRequest — round-trip (puede revelar NC-08, NC-09)', () {
    test('round-trip preserva campos básicos', () {
      final original = AppRequest(
        id: 'r1',
        from: 'u1',
        to: 'u2',
        eventId: 'e1',
        collectiveId: 'c1',
        positionRequestedId: 'p1',
        createdTime: 1700000000000,
        expiresAt: 1700100000000,
        message: 'hello',
        unread: false,
        percentageCoverage: 50.5,
        distanceKm: 100,
        requestDecision: RequestDecision.confirmed,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = AppRequest.fromJSON(json);

      expect(restored.from, original.from);
      expect(restored.to, original.to);
      expect(restored.eventId, original.eventId);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.positionRequestedId, original.positionRequestedId);
      expect(restored.createdTime, original.createdTime);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.message, original.message);
      expect(restored.unread, original.unread);
      expect(restored.percentageCoverage, original.percentageCoverage);
      expect(restored.distanceKm, original.distanceKm);
      expect(restored.requestDecision, original.requestDecision);
    });

    test('NC-09: id se preserva tras round-trip', () {
      // Bug: fromJSON no asigna id desde data["id"]. Tras un round-trip
      // que injecte id en el doc, el id se pierde (queda "" del default).
      final original = AppRequest(id: 'r1', from: 'u1', to: 'u2');
      final json = {...original.toJSON(), 'id': original.id};
      final restored = AppRequest.fromJSON(json);
      expect(
        restored.id,
        original.id,
        reason: 'NC-09: AppRequest.fromJSON no asigna id desde data["id"].',
      );
    });

    test('NC-08: fromJSON con unread null no debería crashear', () {
      // Bug: `unread = data["unread"] ?? ""` asigna String a campo bool.
      try {
        final r = AppRequest.fromJSON({'unread': null, 'from': 'u1'});
        // Si lib silencia el error con un try-catch interno, igual el
        // estado debería ser sane. fromJSON envuelve en try-catch, así
        // que potencialmente no crashea pero deja todo en defaults.
        expect(r.unread, anyOf(isTrue, isFalse),
            reason: 'unread debe ser bool válido tras fromJSON');
      } on TypeError catch (e) {
        fail('NC-08: fromJSON lanza por default "" sobre campo bool. $e');
      }
    });

    test('mapa vacío usa defaults sin crashear', () {
      // El try-catch interno de fromJSON debería protegernos, pero el
      // estado del objeto puede quedar parcial.
      final r = AppRequest.fromJSON(<String, dynamic>{});
      // Lo que SÍ podemos asegurar: el constructor mantiene defaults.
      expect(r.requestDecision, RequestDecision.pending);
    });
  });
}
