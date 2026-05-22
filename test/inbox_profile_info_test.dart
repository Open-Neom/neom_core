// Tests for `InboxProfileInfo` — modelo bien defendido.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/inbox_profile_info.dart';

void main() {
  group('InboxProfileInfo — defaults', () {
    test('constructor con required profileId', () {
      final i = InboxProfileInfo(profileId: 'u1');
      expect(i.profileId, 'u1');
      expect(i.lastTyping, 0);
      expect(i.lastReadAt, 0);
      expect(i.isMuted, isFalse);
      expect(i.isBlocked, isFalse);
      expect(i.metadata, isNull);
    });
  });

  group('InboxProfileInfo — round-trip', () {
    test('preserva todos los campos', () {
      final original = InboxProfileInfo(
        profileId: 'u1',
        lastTyping: 1700000000000,
        lastReadAt: 1700000001000,
        isMuted: true,
        isBlocked: false,
        metadata: {'lang': 'es', 'badge': 'pro'},
      );
      final restored = InboxProfileInfo.fromJSON(original.toJSON());
      expect(restored.profileId, original.profileId);
      expect(restored.lastTyping, original.lastTyping);
      expect(restored.lastReadAt, original.lastReadAt);
      expect(restored.isMuted, original.isMuted);
      expect(restored.isBlocked, original.isBlocked);
      expect(restored.metadata, original.metadata);
    });

    test('mapa vacío usa defaults', () {
      final i = InboxProfileInfo.fromJSON(<String, dynamic>{});
      expect(i.profileId, '');
      expect(i.lastTyping, 0);
      expect(i.isMuted, isFalse);
      expect(i.isBlocked, isFalse);
      expect(i.metadata, isNull);
    });

    test('metadata null se hidrata como null', () {
      final i = InboxProfileInfo.fromJSON({'metadata': null});
      expect(i.metadata, isNull);
    });

    test('metadata como Map se hidrata', () {
      final i = InboxProfileInfo.fromJSON({
        'metadata': {'k': 'v'},
      });
      expect(i.metadata, {'k': 'v'});
    });
  });
}
