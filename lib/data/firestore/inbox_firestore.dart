import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/inbox.dart';
import '../../domain/model/inbox_message.dart';
import '../../domain/model/inbox_profile_info.dart';
import '../../domain/repository/inbox_repository.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/inbox_room_kind.dart';
import '../../utils/enums/inbox_room_type.dart';
import '../../utils/enums/user_role.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'user_firestore.dart';

class InboxFirestore implements InboxRepository {
  final FirebaseFirestore? _injectedFirestore;
  InboxFirestore({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get inboxReference =>
      _firestore.collection(AppFirestoreCollectionConstants.inbox);
  Query<Map<String, dynamic>> get messageReference =>
      _firestore.collectionGroup(AppFirestoreCollectionConstants.messages);

  @override
  Future<bool> addMessage(String inboxRoomId, InboxMessage message,
      {InboxRoomType inboxRoomType = InboxRoomType.profile}) async {
    final cleanRoomId = inboxRoomId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanRoomId)) return false;
    AppConfig.logger.t("Adding Message to inbox $cleanRoomId");

    try {
      await CoreFirestoreGuard.guardWrite(
        () async {
          await inboxReference
              .doc(cleanRoomId)
              .collection(AppFirestoreCollectionConstants.messages)
              .add(message.toJSON());
          if (inboxRoomType == InboxRoomType.profile) {
            await inboxReference
                .doc(cleanRoomId)
                .update({AppFirestoreConstants.lastMessage: message.toJSON()});
          } else {
            // Collective/group rooms may not yet have a pre-existing parent
            // inbox doc (legacy bands or topic channels); merge safely so
            // lastMessage stays fresh without throwing `not-found`.
            await inboxReference.doc(cleanRoomId).set(
              {
                'id': cleanRoomId,
                'roomKind': InboxRoomKind.collective.name,
                AppFirestoreConstants.lastMessage: message.toJSON(),
              },
              SetOptions(merge: true),
            );
          }
        },
        tag: 'InboxFirestore.addMessage',
      );
      AppConfig.logger.i("Last message updated for inbox $cleanRoomId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.addMessage');
    }

    AppConfig.logger.d("Message not send");
    return false;
  }

  /// Ensures a first-class parent `inbox/{collectiveId}` group chat room
  /// document exists and mirrors the collective's current metadata & members so
  /// the chat appears in `InboxPage` / `InboxWebPage` with unread badges.
  Future<Inbox> ensureCollectiveRoom({
    required String collectiveId,
    required String name,
    String photoUrl = '',
    String description = '',
    List<String> profileIds = const [],
    List<String> adminIds = const [],
  }) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return Inbox();

    final cleanMembers = profileIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final cleanAdmins = adminIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    try {
      final docRef = inboxReference.doc(cleanId);
      final existing = await docRef.get();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (existing.exists && existing.data() != null) {
        final inbox = Inbox.fromJSON(existing.data()!)..id = existing.id;
        final updates = <String, dynamic>{
          'id': cleanId,
          'roomKind': InboxRoomKind.collective.name,
          if (name.trim().isNotEmpty) 'name': name.trim(),
          if (photoUrl.trim().isNotEmpty) 'photoUrl': photoUrl.trim(),
          if (description.trim().isNotEmpty) 'description': description.trim(),
          if (cleanMembers.isNotEmpty) 'profileIds': cleanMembers,
          if (cleanAdmins.isNotEmpty) 'adminIds': cleanAdmins,
        };
        await docRef.set(updates, SetOptions(merge: true));
        inbox
          ..roomKind = InboxRoomKind.collective
          ..name = name.trim().isNotEmpty ? name.trim() : inbox.name
          ..photoUrl = photoUrl.trim().isNotEmpty ? photoUrl.trim() : inbox.photoUrl
          ..description = description.trim().isNotEmpty ? description.trim() : inbox.description
          ..profileIds = cleanMembers.isNotEmpty ? cleanMembers : inbox.profileIds
          ..adminIds = cleanAdmins.isNotEmpty ? cleanAdmins : inbox.adminIds;
        return inbox;
      }

      final inbox = Inbox(
        id: cleanId,
        isPrivate: true,
        profileIds: cleanMembers,
        createdTime: now,
        roomKind: InboxRoomKind.collective,
        name: name.trim(),
        photoUrl: photoUrl.trim(),
        description: description.trim(),
        adminIds: cleanAdmins,
      );
      await docRef.set(inbox.toJSON(), SetOptions(merge: true));
      return inbox;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.ensureCollectiveRoom',
      );
      return Inbox(
        id: cleanId,
        roomKind: InboxRoomKind.collective,
        name: name.trim(),
        photoUrl: photoUrl.trim(),
        profileIds: cleanMembers,
        adminIds: cleanAdmins,
      );
    }
  }

  /// Keeps `inbox/{collectiveId}` membership and admins aligned with the
  /// collective's member roster.
  Future<void> syncCollectiveRoomMembers({
    required String collectiveId,
    required List<String> profileIds,
    List<String>? adminIds,
    String? name,
    String? photoUrl,
  }) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      final cleanMembers = profileIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final payload = <String, dynamic>{
        'id': cleanId,
        'roomKind': InboxRoomKind.collective.name,
        'profileIds': cleanMembers,
        if (adminIds != null)
          'adminIds': adminIds
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (photoUrl != null && photoUrl.trim().isNotEmpty)
          'photoUrl': photoUrl.trim(),
      };
      await inboxReference.doc(cleanId).set(payload, SetOptions(merge: true));
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.syncCollectiveRoomMembers',
      );
    }
  }

  /// OPTIMIZED: Now requires inboxId for direct document access instead of scanning all messages
  @override
  Future<bool> handleLikeMessage(String profileId, String messageId, bool isLiked, {String? inboxId}) async {
    final cleanProfileId = profileId.trim();
    final cleanMessageId = messageId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMessageId)) {
      return false;
    }
    AppConfig.logger.t("handleLikeMessage: profileId=$cleanProfileId, messageId=$cleanMessageId, isLiked=$isLiked");
    try {
      if (inboxId != null && inboxId.trim().isNotEmpty) {
        final cleanInboxId = inboxId.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanInboxId)) return false;
        // OPTIMIZED: Direct document access - 1 read instead of scanning all messages
        final messageRef = inboxReference
            .doc(cleanInboxId)
            .collection(AppFirestoreCollectionConstants.messages)
            .doc(cleanMessageId);

        if (isLiked) {
          await messageRef.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([cleanProfileId])});
        } else {
          await messageRef.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([cleanProfileId])});
        }
        AppConfig.logger.d("Message $cleanMessageId like updated directly");
        return true;
      }

      // FALLBACK: Use collectionGroup with limit if inboxId not provided
      // This is less efficient but limited to prevent full scan
      AppConfig.logger.w("handleLikeMessage called without inboxId - using limited collectionGroup query");
      final querySnapshot = await messageReference
          .where(FieldPath.documentId, isEqualTo: cleanMessageId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        if (isLiked) {
          await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([cleanProfileId])});
        } else {
          await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([cleanProfileId])});
        }
        AppConfig.logger.d("Message $cleanMessageId like updated via collectionGroup");
        return true;
      }

      AppConfig.logger.w("Message $cleanMessageId not found");
      return false;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.handleLikeMessage');
      return false;
    }
  }

  DocumentReference _messageRef(String inboxId, String messageId) => inboxReference
      .doc(inboxId)
      .collection(AppFirestoreCollectionConstants.messages)
      .doc(messageId);

  /// Toggle a multi-emoji reaction on a message (reactions: emoji → profileIds).
  Future<bool> reactToMessage(String inboxId, String messageId, String emoji,
      String profileId, {bool remove = false}) async {
    final cleanInboxId = inboxId.trim();
    final cleanMessageId = messageId.trim();
    final cleanProfileId = profileId.trim();
    final safeEmoji = CoreFirestoreGuard.sanitizeFieldSegment(emoji);
    if (!CoreFirestoreGuard.isSafeDocId(cleanInboxId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMessageId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        safeEmoji.isEmpty) {
      return false;
    }
    try {
      await _messageRef(cleanInboxId, cleanMessageId).update({
        'reactions.$safeEmoji': remove
            ? FieldValue.arrayRemove([cleanProfileId])
            : FieldValue.arrayUnion([cleanProfileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.reactToMessage');
      return false;
    }
  }

  /// Pin / unpin a message.
  Future<bool> setMessagePinned(String inboxId, String messageId, bool pinned) async {
    final cleanInboxId = inboxId.trim();
    final cleanMessageId = messageId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanInboxId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMessageId)) {
      return false;
    }
    try {
      await _messageRef(cleanInboxId, cleanMessageId).update({'isPinned': pinned});
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.setMessagePinned');
      return false;
    }
  }

  /// Increments the thread reply count on the parent message.
  Future<void> incrementReplyCount(String inboxId, String parentMessageId) async {
    final cleanInboxId = inboxId.trim();
    final cleanParentId = parentMessageId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanInboxId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanParentId)) {
      return;
    }
    try {
      await _messageRef(cleanInboxId, cleanParentId).update({'replyCount': FieldValue.increment(1)});
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.incrementReplyCount');
    }
  }

  /// Casts a vote on an inline poll. When [allowMultiple] is false (default),
  /// removes the voter from every option before adding to [optionIndex]; when
  /// true, toggles [profileId] on [optionIndex] independently.
  Future<bool> votePoll(
    String inboxId,
    String messageId,
    int optionIndex,
    String profileId, {
    bool allowMultiple = false,
  }) async {
    final cleanInboxId = inboxId.trim();
    final cleanMessageId = messageId.trim();
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanInboxId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMessageId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        optionIndex < 0 ||
        optionIndex > 100) {
      return false;
    }
    try {
      final ref = _messageRef(cleanInboxId, cleanMessageId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>?;
        if (data == null) return;
        final poll = Map<String, dynamic>.from(data['pollData'] ?? {});
        final multi = allowMultiple || (poll['allowMultiple'] == true);
        final votes = Map<String, dynamic>.from(poll['votes'] ?? {});
        final key = optionIndex.toString();
        final currentForKey = List<String>.from(votes[key] ?? []);
        final alreadyVotedThis = currentForKey.contains(cleanProfileId);
        if (!multi) {
          votes.updateAll(
            (k, v) => (List<String>.from(v ?? []))..remove(cleanProfileId),
          );
          if (!alreadyVotedThis) {
            votes[key] = (List<String>.from(votes[key] ?? []))..add(cleanProfileId);
          }
        } else {
          if (alreadyVotedThis) {
            currentForKey.remove(cleanProfileId);
          } else {
            currentForKey.add(cleanProfileId);
          }
          votes[key] = currentForKey;
        }
        poll['votes'] = votes;
        tx.update(ref, {'pollData': poll});
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.votePoll');
      return false;
    }
  }

  /// Edits a sent message text and records `editedTime`.
  Future<bool> editMessage(
    String inboxId,
    String messageId,
    String newText,
  ) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _messageRef(inboxId, messageId).update({
        'text': newText,
        'editedTime': now,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.editMessage',
      );
      return false;
    }
  }

  /// Marks a message as deleted for everyone (WhatsApp-style tombstone).
  Future<bool> deleteMessageForEveryone(
    String inboxId,
    String messageId,
  ) async {
    try {
      await _messageRef(inboxId, messageId).update({
        'isDeletedForEveryone': true,
        'text': '',
        'mediaUrl': '',
        'pollData': null,
        'locationData': null,
        'documentData': null,
        'contactData': null,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.deleteMessageForEveryone',
      );
      return false;
    }
  }

  /// Hides a message only for [profileId] ("Eliminar para mí").
  Future<bool> deleteMessageForMe(
    String inboxId,
    String messageId,
    String profileId,
  ) async {
    try {
      await _messageRef(inboxId, messageId).update({
        'hiddenForProfileIds': FieldValue.arrayUnion([profileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.deleteMessageForMe',
      );
      return false;
    }
  }

  /// Stars or unstars a message for [profileId].
  Future<bool> setMessageStarred(
    String inboxId,
    String messageId,
    String profileId,
    bool starred,
  ) async {
    try {
      await _messageRef(inboxId, messageId).update({
        'starredByProfileIds': starred
            ? FieldValue.arrayUnion([profileId])
            : FieldValue.arrayRemove([profileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.setMessageStarred',
      );
      return false;
    }
  }

  /// Creates a multi-member group room in Firestore.
  Future<Inbox> createGroupRoom({
    required String name,
    String description = '',
    String photoUrl = '',
    required List<String> memberIds,
    required String creatorId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final docRef = inboxReference.doc('group_${now}_${creatorId.hashCode.abs()}');
    final allMembers = <String>{
      if (creatorId.isNotEmpty) creatorId,
      ...memberIds.where((id) => id.isNotEmpty),
    }.toList();
    final group = Inbox(
      id: docRef.id,
      name: name.trim(),
      description: description.trim(),
      photoUrl: photoUrl,
      isPrivate: true,
      roomKind: InboxRoomKind.group,
      profileIds: allMembers,
      adminIds: creatorId.isNotEmpty ? [creatorId] : const [],
      createdTime: now,
    );
    try {
      await docRef.set(group.toJSON());
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'InboxFirestore.createGroupRoom',
      );
    }
    return group;
  }


  @override
  Future<bool> inboxExists(String inboxId) async {
    final cleanId = inboxId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("");

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(cleanId).get();
      if(documentSnapshot.exists){
        return true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.inboxExists');
    }

    AppConfig.logger.d("");
    return false;
  }


  @override
  Future<List<InboxMessage>> retrieveMessages(String inboxId) async {
    final cleanId = inboxId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return [];
    AppConfig.logger.t("Retrieving messages for inbox room $cleanId from firestore");
    List<InboxMessage> messages = [];

    try {
      QuerySnapshot querySnapshot = await inboxReference.doc(cleanId)
          .collection(AppFirestoreCollectionConstants.messages)
          .orderBy(AppFirestoreConstants.createdTime)
          .limitToLast(200)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var messageSnapshot in querySnapshot.docs) {
          final data = messageSnapshot.data();
          if (data == null) continue;
          InboxMessage message = InboxMessage.fromJSON(data as Map<String, dynamic>);
          message.id = messageSnapshot.id;
          messages.add(message);
        }
        AppConfig.logger.t("${messages.length} messages retrieved");
      } else {
        AppConfig.logger.t("No messages found Found");
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.retrieveMessages');
    }

    return messages;
  }


  @override
  Future<bool> addInbox(Inbox inbox) async {
    final cleanId = inbox.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    inbox.id = cleanId;
    AppConfig.logger.d("");

    try {
      await inboxReference.doc(cleanId).set(inbox.toJSON());
      AppConfig.logger.d("");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.addInbox');
    }

    return false;
  }

  @override
  Future<List<Inbox>> getProfileInbox(String profileId) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.t("Getting Inbox for Profile $cleanProfileId from firestore");

    List<Inbox> inboxs = [];

    try {
      // OPTIMIZED: Added limit to prevent loading too many conversations
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: cleanProfileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(50) // Only load last 50 conversations
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for(var documentSnapshot in querySnapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Inbox inbox = Inbox.fromJSON(data as Map<String, dynamic>);
          inbox.id = documentSnapshot.id;

            AppConfig.logger.t('Inbox ${inbox.id} found');
            inboxs.add(inbox);
          }
        }
      AppConfig.logger.d("${inboxs.length} inboxRoom retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getProfileInbox');
    }

    return inboxs;
  }


  @override
  Future<Inbox> getOrCreateInboxRoom(AppProfile profile, AppProfile itemmate) async {
    final cleanProfileId = profile.id.trim();
    final cleanMateId = itemmate.id.trim();
    AppConfig.logger.d("Getting or creating InboxRoom for profile $cleanProfileId");

    Inbox inbox = Inbox();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMateId)) {
      return inbox;
    }

    String inboxRoomId = "${cleanProfileId}_$cleanMateId";
    String mateInboxRoomId = "${cleanMateId}_$cleanProfileId";

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxRoomId).get();
      if(documentSnapshot.exists){
        AppConfig.logger.d("Retrieving inbox from main user");
        final data = documentSnapshot.data();
        if (data != null) {
          inbox = Inbox.fromJSON(data);
          inbox.id = documentSnapshot.id;
        }
      } else {
        DocumentSnapshot itemmateDocumentSnapshot = await inboxReference.doc(mateInboxRoomId).get();
        if(itemmateDocumentSnapshot.exists){
          AppConfig.logger.i("Retrieving inbox from itemmate");
          final itemmateData = itemmateDocumentSnapshot.data();
          if (itemmateData != null) {
            inbox = Inbox.fromJSON(itemmateData as Map<String, dynamic>);
            inbox.id = itemmateDocumentSnapshot.id;
          }
        } else {
          AppConfig.logger.i("Creating inbox from main user");
          inbox.id = inboxRoomId;
          inbox.profileIds = [cleanProfileId, cleanMateId];

          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
        }
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getOrCreateInboxRoom');

      // Fallback for offline mesh swarm:
      // Construct the inbox room ID locally if Firestore is unreachable,
      // allowing active swarm peers to engage in messaging.
      inbox.id = inboxRoomId;
      inbox.profileIds = [cleanProfileId, cleanMateId];
    }

    AppConfig.logger.d(inbox.toString());
    return inbox;
  }


  @override
  void searchInboxByName(String searchField) {
    // TODO: implement searchInboxByName
    throw UnimplementedError();
  }

  @override
  Stream<List<InboxMessage>> messageStream(String inboxId, {int limit = 50}) {
    final cleanId = inboxId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) {
      return Stream<List<InboxMessage>>.value(const <InboxMessage>[]);
    }
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    AppConfig.logger.t("Iniciando stream de mensajes para: $cleanId (limit: $safeLimit)");

    return inboxReference
        .doc(cleanId)
        .collection(AppFirestoreCollectionConstants.messages)
        .orderBy(AppFirestoreConstants.createdTime, descending: true) // Most recent first
        .limit(safeLimit) // Limit to reduce Firestore reads
        .snapshots()
        .map((snapshot) {
      // Reverse to show oldest first in UI
      return snapshot.docs.reversed.map((doc) {
        final data = doc.data();
        InboxMessage message = InboxMessage.fromJSON(data);
        message.id = doc.id;
        return message;
      }).toList();
    });
  }

  /// Dedicated Customer Support thread per user (`{profileId}_support`),
  /// separate from the appBot announcements room. Marked `isSupportRoom: true`
  /// so the ERP lists it the moment it's created.
  Future<Inbox> getOrCreateSupportRoom(String profileId) async {
    Inbox inbox = Inbox();
    final inboxRoomId = "${profileId}_${CoreConstants.appSupport}";
    try {
      final doc = await inboxReference.doc(inboxRoomId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          inbox = Inbox.fromJSON(data);
          inbox.id = doc.id;
        }
        // Backfill the marker on rooms created before this flag existed.
        if (!inbox.isSupportRoom) {
          inbox.isSupportRoom = true;
          await inboxReference.doc(inboxRoomId)
              .set({'isSupportRoom': true}, SetOptions(merge: true));
        }
      } else {
        inbox.id = inboxRoomId;
        inbox.profileIds = [profileId];
        inbox.isSupportRoom = true;
        inbox.createdTime = DateTime.now().millisecondsSinceEpoch;
        await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
        // Official-channel welcome: simply make it clear that support lives here
        // (web + app). No comparisons, no mention of other channels.
        final appName = AppProperties.getAppName();
        await addMessage(inboxRoomId, InboxMessage(
          ownerId: CoreConstants.appBot,
          profileName: appName,
          text: 'Bienvenido a Atención y Soporte de $appName. Este es tu canal '
              'oficial de atención, disponible en la web y en la app. Escríbenos '
              'por aquí y con gusto te ayudamos.',
          referenceId: 'system',
          createdTime: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getOrCreateSupportRoom');
    }
    return inbox;
  }

  /// Shared internal team channel (`team_room`) — the staff's home inside the
  /// platform. Members are everyone at [UserRole.support] or above; the caller's
  /// id is always merged in so they appear in their own inbox list. Plaintext.
  Future<Inbox> getOrCreateTeamRoom(String currentProfileId) async {
    Inbox inbox = Inbox();
    const inboxRoomId = CoreConstants.teamRoomId;
    try {
      // Resolve current staff so the channel lists everyone (best-effort).
      List<String> staffIds = [];
      try {
        staffIds = await UserFirestore().getProfileIdsByMinRole(UserRole.support);
      } catch (_) {}
      if (currentProfileId.isNotEmpty && !staffIds.contains(currentProfileId)) {
        staffIds.add(currentProfileId);
      }

      final doc = await inboxReference.doc(inboxRoomId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          inbox = Inbox.fromJSON(data);
          inbox.id = doc.id;
        }
        // Keep membership in sync (new staff / first open) + backfill marker.
        final merged = {...inbox.profileIds, ...staffIds}.toList();
        final needsUpdate = !inbox.isTeamRoom || merged.length != inbox.profileIds.length;
        if (needsUpdate) {
          inbox.isTeamRoom = true;
          inbox.profileIds = merged;
          await inboxReference.doc(inboxRoomId)
              .set({'isTeamRoom': true, 'profileIds': merged}, SetOptions(merge: true));
        }
      } else {
        inbox.id = inboxRoomId;
        inbox.profileIds = staffIds;
        inbox.isTeamRoom = true;
        inbox.createdTime = DateTime.now().millisecondsSinceEpoch;
        await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
        final appName = AppProperties.getAppName();
        await addMessage(inboxRoomId, InboxMessage(
          ownerId: CoreConstants.appBot,
          profileName: appName,
          text: 'Este es el canal interno del equipo de $appName. Coordinen aquí '
              'la atención, ventas y operación — todo en un solo lugar, dentro de '
              'la plataforma.',
          referenceId: 'system',
          createdTime: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getOrCreateTeamRoom');
    }
    return inbox;
  }

  @override
  Future<Inbox> getOrCreateAppBotRoom(String profileId) async {
    AppConfig.logger.t("getOrCreateAppBotRoom for profile $profileId");

    Inbox inbox = Inbox();

    String inboxRoomId = "${profileId}_${CoreConstants.appBot}";

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxRoomId).get();
      if(documentSnapshot.exists){
        AppConfig.logger.d("Retrieving inbox from main user");
        final data = documentSnapshot.data();
        if (data != null) {
          inbox = Inbox.fromJSON(data);
          inbox.id = documentSnapshot.id;
        }
      } else {
        AppConfig.logger.d("Creating inbox for AppBot");
        inbox.id = inboxRoomId;
        List<String> profileIds = [];
        profileIds.add(profileId);
        inbox.profileIds = profileIds;
          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getOrCreateAppBotRoom');
    }

    AppConfig.logger.d(inbox.toString());
    return inbox;
  }

  /// Updates the customer-support handoff state of a room (Itzli ↔ human).
  Future<void> setSupportHandoff(String roomId, Map<String, dynamic> data) async {
    final cleanRoomId = roomId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanRoomId)) return;
    final safeData = CoreFirestoreGuard.sanitizeUpdateMap(
      data,
      immutableKeys: const {'id', 'createdTime'},
    );
    if (safeData.isEmpty) return;
    try {
      await inboxReference.doc(cleanRoomId).set(safeData, SetOptions(merge: true));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.setSupportHandoff');
    }
  }

  /// Live queue of support threads that need a human agent (Atención al
  /// Cliente), most recently active first.
  Stream<List<Inbox>> streamSupportQueue() {
    return inboxReference
        .where('isSupportRoom', isEqualTo: true)
        .limit(200)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs.map((d) {
            final inbox = Inbox.fromJSON(d.data());
            inbox.id = d.id;
            return inbox;
          }).toList();

          final filtered = rooms.where((r) {
            return r.needsHuman ||
                (r.handlerMode == 'human' && r.lastUserAt > r.lastHumanAt);
          }).toList();

          filtered.sort((a, b) => b.lastUserAt.compareTo(a.lastUserAt));
          return filtered;
        });
  }

  /// All support threads (every `{profileId}_support` room), most recently
  /// active first — so the ERP lists each one the moment it's created.
  /// Sorted client-side to avoid excluding rooms missing the order field.
  Stream<List<Inbox>> streamRecentSupportRooms({int limit = 100}) {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 100, maxLimit: 300);
    return inboxReference
        .where('isSupportRoom', isEqualTo: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs.map((d) {
            final inbox = Inbox.fromJSON(d.data());
            inbox.id = d.id;
            return inbox;
          }).toList();
          rooms.sort((a, b) {
            final byUser = b.lastUserAt.compareTo(a.lastUserAt);
            return byUser != 0 ? byUser : b.createdTime.compareTo(a.createdTime);
          });
          return rooms;
        });
  }

  /// One-shot fetch of the support queue (needs-human threads).
  Future<List<Inbox>> getSupportQueue() async {
    try {
      final snap = await inboxReference
          .where('needsHuman', isEqualTo: true)
          .orderBy('lastUserAt', descending: true)
          .limit(200)
          .get();
      return snap.docs.map((d) {
        final inbox = Inbox.fromJSON(d.data());
        inbox.id = d.id;
        return inbox;
      }).toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getSupportQueue');
      return [];
    }
  }

  @override
  Stream<InboxProfileInfo> getInboxProfileInfo(String roomId, String profileId) {
    final cleanRoomId = roomId.trim();
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanRoomId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return Stream<InboxProfileInfo>.value(
        InboxProfileInfo.fromJSON(const <String, dynamic>{}),
      );
    }
    return inboxReference.doc(cleanRoomId).collection(AppFirestoreCollectionConstants.roomProfiles)
        .doc(cleanProfileId).snapshots().map((doc) => InboxProfileInfo.fromJSON(doc.data() ?? {}));
  }

  /// OPTIMIZED: Obtiene el conteo de mensajes sin leer para un perfil.
  /// Un mensaje se considera no leído si:
  /// - El lastMessage.ownerId != profileId (no es del usuario actual)
  /// - El lastMessage.seenTime == 0 (no ha sido visto)
  Future<int> getUnreadInboxCount(String profileId) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return 0;
    AppConfig.logger.t("Getting unread inbox count for profile $cleanProfileId");
    int unreadCount = 0;

    try {
      // OPTIMIZED: Added limit and orderBy to reduce reads - only check most recent conversations
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: cleanProfileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(20) // Only check last 20 conversations for unread count
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          try {
            final data = documentSnapshot.data();
            if (data == null) continue;
            Inbox inbox = Inbox.fromJSON(data as Map<String, dynamic>);

            // Verificar si hay mensaje sin leer
            if (inbox.lastMessage != null &&
                inbox.lastMessage!.ownerId.isNotEmpty &&
                inbox.lastMessage!.ownerId != cleanProfileId &&
                inbox.lastMessage!.seenTime == 0) {
              unreadCount++;
            }
          } catch (docError) {
            AppConfig.logger.w("Skipping malformed inbox doc ${documentSnapshot.id}: $docError");
            continue;
          }
        }
      }
      AppConfig.logger.d("Unread inbox count: $unreadCount");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getUnreadInboxCount');
    }

    return unreadCount;
  }

  @override
  Future<void> setLastTyping(String roomId, String profileId) async {
    final cleanRoomId = roomId.trim();
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanRoomId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return;
    }
    try {
      await inboxReference.doc(cleanRoomId)
          .collection(AppFirestoreCollectionConstants.roomProfiles)
          .doc(cleanProfileId).set({
            AppFirestoreConstants.lastTyping: DateTime.now().millisecondsSinceEpoch,
          });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.setLastTyping');
    }
  }

  /// Marca el último mensaje de una conversación como leído.
  /// Solo actualiza si el mensaje no es del usuario actual y no ha sido visto.
  Future<void> markLastMessageAsRead(String inboxId, String currentUserId) async {
    AppConfig.logger.t("Marking last message as read for inbox $inboxId");

    try {
      DocumentSnapshot docSnapshot = await inboxReference.doc(inboxId).get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data();
      if (data == null) return;

      Inbox inbox = Inbox.fromJSON(data as Map<String, dynamic>);

      // Solo marcar como leído si el mensaje es de otra persona y no ha sido visto
      if (inbox.lastMessage != null &&
          inbox.lastMessage!.ownerId != currentUserId &&
          inbox.lastMessage!.seenTime == 0) {

        await inboxReference.doc(inboxId).update({
          '${AppFirestoreConstants.lastMessage}.${AppFirestoreConstants.seenTime}':
              DateTime.now().millisecondsSinceEpoch,
        });

        AppConfig.logger.d("Last message marked as read for inbox $inboxId");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.markLastMessageAsRead');
    }
  }

  /// Stream para obtener el conteo de mensajes sin leer en tiempo real.
  /// DEPRECATED: Use getUnreadInboxCount() with polling instead to reduce Firestore reads.
  /// Limita a 20 conversaciones para evitar lecturas excesivas.
  @Deprecated('Use getUnreadInboxCount() with polling instead to reduce Firestore reads')
  Stream<int> getUnreadInboxCountStream(String profileId) {
    AppConfig.logger.t("Starting unread inbox count stream for profile $profileId");

    return inboxReference
        .where(AppFirestoreConstants.profileIds, arrayContains: profileId)
        .orderBy(AppFirestoreConstants.createdTime, descending: true)
        .limit(20) // OPTIMIZED: Reduced from 50 to 20 to reduce Firestore reads
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        Inbox inbox = Inbox.fromJSON(data);

        if (inbox.lastMessage != null &&
            inbox.lastMessage!.ownerId != profileId &&
            inbox.lastMessage!.seenTime == 0) {
          unreadCount++;
        }
      }

      AppConfig.logger.d("Unread inbox count (stream): $unreadCount");
      return unreadCount;
    });
  }

}
