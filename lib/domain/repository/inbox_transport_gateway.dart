import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../utils/enums/inbox_room_type.dart';
import '../model/app_profile.dart';
import '../model/inbox.dart';
import '../model/inbox_message.dart';
import '../model/inbox_profile_info.dart';

/// Metadata for a picked document attachment (`PDF`, `DOCX`, receipt, etc.).
class InboxPickedDocument {
  final String filePath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final Uint8List? bytes;

  const InboxPickedDocument({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.bytes,
  });

  String get path => filePath;
  String get name => fileName;
  String get extension => fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
}

/// Optional platform/app media adapter registered via Sint DI so apps with
/// native pickers/compressors/players (such as `Blup`) enhance `neom_inbox`
/// without forcing extra native plugin dependencies onto lightweight apps.
abstract class InboxMediaAdapter {
  /// Pick a document (`PDF`, `DOCX`, `XLSX`, `TXT`, etc.) from local storage.
  Future<InboxPickedDocument?> pickDocument();

  /// Optionally compress/prepare a native video file before sending.
  Future<String?> prepareOutgoingVideoPath(String sourcePath) async =>
      sourcePath;

  /// Optional inline or modal video player builder for local/received MP4s.
  Widget? buildInlineVideoPreview(
    BuildContext context,
    InboxMessage message, {
    required bool sendByMe,
  }) => null;

  /// Open or share a local file (`PDF`, document, MP4) via OS sheet.
  Future<bool> openOrShareLocalFile(
    String filePath, {
    String? title,
    String? mimeType,
  }) async => false;

  /// Open a location message inside the host app's native map tab/screen.
  /// Returns `true` if handled internally; otherwise `neom_inbox` launches an
  /// external map deep-link.
  Future<bool> openLocation(
    BuildContext context, {
    required double lat,
    required double lng,
    String label = '',
  }) async => false;

  /// Optional quick-pick list of shareable contacts / verified BLE peers.
  Future<List<Map<String, dynamic>>> loadShareableContacts() async => const [];

  /// Handle tapping "Agregar / Verificar" on an incoming contact card.
  Future<bool> importContactCard(
    BuildContext context,
    Map<String, dynamic> contactData,
  ) async => false;
}

/// Official Open Neom multi-transport messaging contract.
///
/// Decouples `neom_inbox` UI & controllers from direct `FirebaseFirestore`
/// calls so every Open Neom app shares the exact same WhatsApp-grade UI:
/// - Cloud apps (`Cyberneom`, `Gigmeout`, `Emxi`, `Itzli`) use
///   `FirestoreInboxTransport`.
/// - Offline-first / mesh apps (`Blup`) register `BlupHybridInboxTransport`
///   combining BLE, authenticated local Wi-Fi, Río Colmena multi-hop drops,
///   encrypted groups, proximity distance channels, and optional Cloud sync.
abstract class InboxTransportGateway {
  /// True when this gateway works in guest / local-identity mode without
  /// requiring a Firebase authenticated account.
  bool get supportsGuestSession => false;

  /// True when this gateway can deliver rich media & messages offline over
  /// local mesh (BLE / Wi-Fi Direct / Río Colmena) without internet.
  bool get supportsOfflineMeshMedia => false;

  /// Resolves the active local or cloud sender profile.
  AppProfile? resolveActiveProfile() => null;

  /// Emits whenever rooms or unread states change asynchronously (e.g., incoming
  /// BLE / Wi-Fi / Río Colmena message or group invite).
  Stream<void> get roomsChanged => const Stream<void>.empty();

  /// Loads conversations (1:1, groups, distance channels, support) for [profileId].
  Future<List<Inbox>> loadRooms(String profileId);

  /// Resolves participant profiles for avatar/name display.
  Future<Map<String, AppProfile>> resolveProfiles(List<String> profileIds);

  /// Resolves a single peer profile by ID.
  Future<AppProfile?> resolveProfile(String profileId);

  /// Creates or opens a 1:1 direct room.
  Future<Inbox> getOrCreateDirectRoom(AppProfile me, AppProfile peer);

  /// Creates a new multi-member group room (cloud, mesh, or hybrid).
  Future<Inbox> createGroupRoom({
    required String name,
    String description = '',
    String photoUrl = '',
    required List<String> memberIds,
    required String creatorId,
    String transportMode = 'cloud',
  });

  /// Streams chronological messages for [roomId].
  Stream<List<InboxMessage>> watchMessages(String roomId, {Inbox? room});

  /// Sends a message through the appropriate transport for [roomId].
  Future<bool> sendMessage(
    String roomId,
    InboxMessage message, {
    Inbox? room,
    InboxRoomType roomType = InboxRoomType.profile,
  });

  /// Toggles an emoji reaction on [message].
  Future<bool> reactToMessage(
    String roomId,
    InboxMessage message,
    String emoji,
    String profileId, {
    required bool remove,
  });

  /// Casts or toggles a vote on an inline poll message.
  Future<bool> votePoll(
    String roomId,
    InboxMessage message,
    int optionIndex,
    String profileId, {
    bool allowMultiple = false,
  });

  /// Pins or unpins a message in [roomId].
  Future<bool> setMessagePinned(
    String roomId,
    InboxMessage message,
    bool pinned,
  );

  /// Toggles heart/like on [message].
  Future<bool> toggleLikeMessage(
    String roomId,
    InboxMessage message,
    String profileId,
    bool currentlyLiked,
  );

  /// Edits the text of an already-sent message (`editedTime` updated).
  Future<bool> editMessage(
    String roomId,
    InboxMessage message,
    String newText,
  );

  /// Deletes a message for everyone in the conversation (tombstone).
  Future<bool> deleteMessageForEveryone(
    String roomId,
    InboxMessage message,
    String actorId,
  );

  /// Hides a message only for [actorId] ("Eliminar para mí").
  Future<bool> deleteMessageForMe(
    String roomId,
    InboxMessage message,
    String actorId,
  );

  /// Toggles starred (`⭐`) status on [message] for [actorId].
  Future<bool> toggleStarMessage(
    String roomId,
    InboxMessage message,
    String actorId,
    bool starred,
  );

  /// Marks the room's incoming messages as read by [profileId].
  Future<void> markRoomRead(String roomId, String profileId);

  /// Watches typing / presence info for [mateId] in [roomId].
  Stream<InboxProfileInfo> watchTyping(String roomId, String mateId);

  /// Publishes a typing heartbeat for [profileId] in [roomId].
  Future<void> sendTyping(String roomId, String profileId);
}
