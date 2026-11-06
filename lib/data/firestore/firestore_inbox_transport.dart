import 'dart:async';

import '../../domain/model/app_profile.dart';
import '../../domain/model/inbox.dart';
import '../../domain/model/inbox_message.dart';
import '../../domain/model/inbox_profile_info.dart';
import '../../domain/repository/inbox_transport_gateway.dart';
import '../../utils/enums/inbox_room_type.dart';
import 'inbox_firestore.dart';
import 'profile_firestore.dart';

/// Default Cloud Open Neom implementation of [InboxTransportGateway] backed by
/// [InboxFirestore] and [ProfileFirestore].
class FirestoreInboxTransport extends InboxTransportGateway {
  FirestoreInboxTransport({
    InboxFirestore? inboxFirestore,
    ProfileFirestore? profileFirestore,
  }) : _inboxFirestoreFactory = (() => inboxFirestore ?? InboxFirestore()),
       _profileFirestoreFactory = (() => profileFirestore ?? ProfileFirestore());

  final InboxFirestore Function() _inboxFirestoreFactory;
  final ProfileFirestore Function() _profileFirestoreFactory;

  InboxFirestore? _inboxFirestore;
  ProfileFirestore? _profileFirestore;

  InboxFirestore get inboxFirestore =>
      _inboxFirestore ??= _inboxFirestoreFactory();
  ProfileFirestore get profileFirestore =>
      _profileFirestore ??= _profileFirestoreFactory();

  @override
  Future<List<Inbox>> loadRooms(String profileId) {
    if (profileId.isEmpty) return Future.value(<Inbox>[]);
    return inboxFirestore.getProfileInbox(profileId);
  }

  @override
  Future<Map<String, AppProfile>> resolveProfiles(List<String> profileIds) async {
    if (profileIds.isEmpty) return <String, AppProfile>{};
    return await profileFirestore.retrieveFromList(profileIds);
  }

  @override
  Future<AppProfile?> resolveProfile(String profileId) async {
    if (profileId.isEmpty) return null;
    return await profileFirestore.retrieve(profileId);
  }

  @override
  Future<Inbox> getOrCreateDirectRoom(AppProfile me, AppProfile peer) {
    return inboxFirestore.getOrCreateInboxRoom(me, peer);
  }

  @override
  Future<Inbox> createGroupRoom({
    required String name,
    String description = '',
    String photoUrl = '',
    required List<String> memberIds,
    required String creatorId,
    String transportMode = 'cloud',
  }) {
    return inboxFirestore.createGroupRoom(
      name: name,
      description: description,
      photoUrl: photoUrl,
      memberIds: memberIds,
      creatorId: creatorId,
    );
  }

  @override
  Stream<List<InboxMessage>> watchMessages(String roomId, {Inbox? room}) {
    return inboxFirestore.messageStream(roomId);
  }

  @override
  Future<bool> sendMessage(
    String roomId,
    InboxMessage message, {
    Inbox? room,
    InboxRoomType roomType = InboxRoomType.profile,
  }) {
    return inboxFirestore.addMessage(
      roomId,
      message,
      inboxRoomType: roomType,
    );
  }

  @override
  Future<bool> reactToMessage(
    String roomId,
    InboxMessage message,
    String emoji,
    String profileId, {
    required bool remove,
  }) {
    return inboxFirestore.reactToMessage(
      roomId,
      message.id,
      emoji,
      profileId,
      remove: remove,
    );
  }

  @override
  Future<bool> votePoll(
    String roomId,
    InboxMessage message,
    int optionIndex,
    String profileId, {
    bool allowMultiple = false,
  }) {
    return inboxFirestore.votePoll(
      roomId,
      message.id,
      optionIndex,
      profileId,
      allowMultiple: allowMultiple,
    );
  }

  @override
  Future<bool> setMessagePinned(
    String roomId,
    InboxMessage message,
    bool pinned,
  ) {
    return inboxFirestore.setMessagePinned(roomId, message.id, pinned);
  }

  @override
  Future<bool> toggleLikeMessage(
    String roomId,
    InboxMessage message,
    String profileId,
    bool currentlyLiked,
  ) {
    return inboxFirestore.handleLikeMessage(
      profileId,
      message.id,
      currentlyLiked,
      inboxId: roomId,
    );
  }

  @override
  Future<bool> editMessage(
    String roomId,
    InboxMessage message,
    String newText,
  ) {
    return inboxFirestore.editMessage(roomId, message.id, newText);
  }

  @override
  Future<bool> deleteMessageForEveryone(
    String roomId,
    InboxMessage message,
    String actorId,
  ) {
    return inboxFirestore.deleteMessageForEveryone(roomId, message.id);
  }

  @override
  Future<bool> deleteMessageForMe(
    String roomId,
    InboxMessage message,
    String actorId,
  ) {
    return inboxFirestore.deleteMessageForMe(roomId, message.id, actorId);
  }

  @override
  Future<bool> toggleStarMessage(
    String roomId,
    InboxMessage message,
    String actorId,
    bool starred,
  ) {
    return inboxFirestore.setMessageStarred(
      roomId,
      message.id,
      actorId,
      starred,
    );
  }

  @override
  Future<void> markRoomRead(String roomId, String profileId) {
    return inboxFirestore.markLastMessageAsRead(roomId, profileId);
  }

  @override
  Stream<InboxProfileInfo> watchTyping(String roomId, String mateId) {
    return inboxFirestore.getInboxProfileInfo(roomId, mateId);
  }

  @override
  Future<void> sendTyping(String roomId, String profileId) {
    return inboxFirestore.setLastTyping(roomId, profileId);
  }
}
