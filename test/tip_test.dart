// Tests for `Tip` — propinas (live tips, profile tips, post tips).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/tip.dart';
import 'package:neom_core/utils/enums/tip_tier.dart';

void main() {
  group('Tip — defaults', () {
    test('constructor sin params', () {
      final t = Tip();
      expect(t.id, '');
      expect(t.senderId, '');
      expect(t.senderName, '');
      expect(t.senderAvatarUrl, '');
      expect(t.recipientId, '');
      expect(t.recipientName, '');
      expect(t.tier, TipTier.cafe);
      expect(t.amount, 0);
      expect(t.message, isNull);
      expect(t.contextType, isNull);
      expect(t.contextId, isNull);
      expect(t.createdTime, 0);
    });

    test('parámetros nombrados', () {
      final t = Tip(
        id: 't1',
        senderId: 'u1',
        senderName: 'Ana',
        recipientId: 'u2',
        recipientName: 'Juan',
        tier: TipTier.cafe,
        amount: 5.0,
        message: 'Excelente!',
        contextType: 'live',
        contextId: 'live_1',
        createdTime: 1700000000000,
      );
      expect(t.id, 't1');
      expect(t.senderName, 'Ana');
      expect(t.recipientName, 'Juan');
      expect(t.amount, 5.0);
      expect(t.message, 'Excelente!');
      expect(t.contextType, 'live');
      expect(t.contextId, 'live_1');
    });
  });

  group('Tip — toJSON', () {
    test('contiene 12 llaves', () {
      final json = Tip().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'senderId', 'senderName', 'senderAvatarUrl',
          'recipientId', 'recipientName', 'tier', 'amount',
          'message', 'contextType', 'contextId', 'createdTime',
        ]),
      );
    });

    test('tier como string (.name)', () {
      expect(Tip(tier: TipTier.cafe).toJSON()['tier'], 'cafe');
    });

    test('campos opcionales null serializan como null', () {
      final json = Tip().toJSON();
      expect(json['message'], isNull);
      expect(json['contextType'], isNull);
      expect(json['contextId'], isNull);
    });
  });

  group('Tip — round-trip', () {
    test('preserva todos los campos', () {
      final original = Tip(
        id: 't1',
        senderId: 'u1', senderName: 'Ana',
        recipientId: 'u2', recipientName: 'Juan',
        tier: TipTier.cafe,
        amount: 10.5,
        message: 'Gracias',
        contextType: 'profile',
        contextId: 'p_1',
        createdTime: 1700000000000,
      );
      final restored = Tip.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.senderName, original.senderName);
      expect(restored.recipientName, original.recipientName);
      expect(restored.tier, original.tier);
      expect(restored.amount, original.amount);
      expect(restored.message, original.message);
      expect(restored.contextType, original.contextType);
      expect(restored.contextId, original.contextId);
      expect(restored.createdTime, original.createdTime);
    });

    test('amount como string se parsea', () {
      final t = Tip.fromJSON({'amount': '5.50'});
      expect(t.amount, 5.50);
    });

    test('amount null usa 0', () {
      final t = Tip.fromJSON({'amount': null});
      expect(t.amount, 0);
    });

    test('mapa vacío usa defaults', () {
      final t = Tip.fromJSON(<String, dynamic>{});
      expect(t.id, '');
      expect(t.tier, TipTier.cafe);
      expect(t.amount, 0);
      expect(t.message, isNull);
    });

    test('tier desconocido cae a cafe', () {
      final t = Tip.fromJSON({'tier': 'unknown_tier'});
      expect(t.tier, TipTier.cafe);
    });
  });
}
