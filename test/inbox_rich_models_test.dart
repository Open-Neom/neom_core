import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/inbox.dart';
import 'package:neom_core/domain/model/inbox_message.dart';
import 'package:neom_core/domain/repository/inbox_transport_gateway.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';
import 'package:neom_core/utils/enums/inbox_room_kind.dart';

void main() {
  group('Open Neom Rich Inbox & InboxMessage Models', () {
    test('InboxRoomKind infers nearby, group, support, team and direct rooms', () {
      final nearby = Inbox(id: 'blup_nearby_public', isPrivate: false);
      expect(nearby.roomKind, InboxRoomKind.nearbyZone);
      expect(nearby.isNearbyChannel, isTrue);
      expect(nearby.isMeshBacked, isTrue);

      final group = Inbox(
        id: 'group_vecinos_1',
        name: 'Vecinos Colonia Roma',
        profileIds: const ['u1', 'u2', 'u3'],
        adminIds: const ['u1'],
        pinnedByProfileIds: const ['u1'],
        mutedByProfileIds: const ['u2'],
        transportMode: 'mesh',
        groupKeyId: 'blup-group://v1?id=abc&name=Vecinos&key=xyz',
      );
      expect(group.roomKind, InboxRoomKind.group);
      expect(group.isGroup, isTrue);
      expect(group.isMeshBacked, isTrue);
      expect(group.isPinnedBy('u1'), isTrue);
      expect(group.isPinnedBy('u3'), isFalse);
      expect(group.isMutedBy('u2'), isTrue);

      final json = group.toJSON();
      json['id'] = group.id;
      final restored = Inbox.fromJSON(json);
      expect(restored.id, 'group_vecinos_1');
      expect(restored.roomKind, InboxRoomKind.group);
      expect(restored.name, 'Vecinos Colonia Roma');
      expect(restored.adminIds, ['u1']);
      expect(restored.pinnedByProfileIds, ['u1']);
      expect(restored.mutedByProfileIds, ['u2']);
      expect(restored.transportMode, 'mesh');
      expect(restored.groupKeyId, contains('blup-group://v1'));
    });

    test('InboxMessage round-trips WhatsApp-grade rich fields without id key in toJSON', () {
      final original = InboxMessage(
        id: 'msg_rich_1',
        ownerId: 'alice',
        profileName: 'Alice',
        text: '¿Dónde compramos los tamales?',
        type: AppMediaType.poll,
        referenceId: 'msg_prev_0',
        replyData: {
          'id': 'msg_prev_0',
          'senderName': 'Bob',
          'text': 'Hay reunión a las 8pm',
          'mediaType': 'text',
        },
        pollData: {
          'question': '¿Dónde compramos los tamales?',
          'options': ['Doña Chonita', 'La Esquina'],
          'allowMultiple': true,
          'votes': {
            '0': ['alice', 'bob'],
          },
        },
        localFilePath: '/tmp/local_preview.jpg',
        deliveryStatus: 'seen',
        deliveredTime: 1700000010,
        seenTime: 1700000020,
        editedTime: 1700000030,
        isForwarded: true,
        starredByProfileIds: const ['alice'],
        hiddenForProfileIds: const ['charlie'],
        hopCount: 2,
        distanceMeters: 84.6,
        createdTime: 1700000000,
      );

      expect(original.hasReply, isTrue);
      expect(original.effectiveMediaSource, '/tmp/local_preview.jpg');
      expect(original.isStarredBy('alice'), isTrue);
      expect(original.isHiddenFor('charlie'), isTrue);
      expect(original.isHiddenFor('alice'), isFalse);

      final map = original.toJSON();
      expect(map.containsKey('id'), isFalse);

      final restored = InboxMessage.fromJSON({'id': original.id, ...map});
      expect(restored.id, 'msg_rich_1');
      expect(restored.type, AppMediaType.poll);
      expect(restored.replyData?['senderName'], 'Bob');
      expect(restored.pollData?['allowMultiple'], isTrue);
      expect(restored.deliveryStatus, 'seen');
      expect(restored.deliveredTime, 1700000010);
      expect(restored.editedTime, 1700000030);
      expect(restored.isForwarded, isTrue);
      expect(restored.isStarredBy('alice'), isTrue);
      expect(restored.isHiddenFor('charlie'), isTrue);
      expect(restored.hopCount, 2);
      expect(restored.distanceMeters, closeTo(84.6, 0.01));
    });

    test('InboxPickedDocument exposes convenient path, name, and extension getters', () {
      const doc = InboxPickedDocument(
        filePath: '/tmp/recibo_cfe_octubre.PDF',
        fileName: 'recibo_cfe_octubre.PDF',
        mimeType: 'application/pdf',
        sizeBytes: 42000,
      );
      expect(doc.path, '/tmp/recibo_cfe_octubre.PDF');
      expect(doc.name, 'recibo_cfe_octubre.PDF');
      expect(doc.extension, 'pdf');
    });
  });
}
