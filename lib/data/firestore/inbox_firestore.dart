import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../utils/enums/user_role.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/inbox.dart';
import '../../domain/model/inbox_message.dart';
import '../../domain/model/inbox_profile_info.dart';
import '../../domain/repository/inbox_repository.dart';

import '../../utils/constants/core_constants.dart';
import '../../utils/enums/inbox_room_type.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'user_firestore.dart';

class InboxFirestore implements InboxRepository {
  
  final inboxReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.inbox);
  final messageReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.messages);

  @override
  Future<bool> addMessage(String inboxRoomId, InboxMessage message,
      {InboxRoomType inboxRoomType = InboxRoomType.profile}) async {
    AppConfig.logger.t("Adding Message to inbox $inboxRoomId");

    try {
      await inboxReference.doc(inboxRoomId).collection(AppFirestoreCollectionConstants.messages)
          .add(message.toJSON());
      AppConfig.logger.d("${message.text} message added");

      if(inboxRoomType == InboxRoomType.profile) {
        await inboxReference.doc(inboxRoomId)
            .update({AppFirestoreConstants.lastMessage: message.toJSON()});
      }

      AppConfig.logger.i("${message.text} last message added");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.addMessage');
    }

    AppConfig.logger.d("Message not send");
    return false;
  }

  /// OPTIMIZED: Now requires inboxId for direct document access instead of scanning all messages
  @override
  Future<bool> handleLikeMessage(String profileId, String messageId, bool isLiked, {String? inboxId}) async {
    AppConfig.logger.t("handleLikeMessage: profileId=$profileId, messageId=$messageId, isLiked=$isLiked");
    try {
      if (inboxId != null && inboxId.isNotEmpty) {
        // OPTIMIZED: Direct document access - 1 read instead of scanning all messages
        final messageRef = inboxReference
            .doc(inboxId)
            .collection(AppFirestoreCollectionConstants.messages)
            .doc(messageId);

        if (isLiked) {
          await messageRef.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([profileId])});
        } else {
          await messageRef.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([profileId])});
        }
        AppConfig.logger.d("Message $messageId like updated directly");
        return true;
      }

      // FALLBACK: Use collectionGroup with limit if inboxId not provided
      // This is less efficient but limited to prevent full scan
      AppConfig.logger.w("handleLikeMessage called without inboxId - using limited collectionGroup query");
      final querySnapshot = await messageReference
          .where(FieldPath.documentId, isEqualTo: messageId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        if (isLiked) {
          await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([profileId])});
        } else {
          await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([profileId])});
        }
        AppConfig.logger.d("Message $messageId like updated via collectionGroup");
        return true;
      }

      AppConfig.logger.w("Message $messageId not found");
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
    try {
      await _messageRef(inboxId, messageId).update({
        'reactions.$emoji': remove
            ? FieldValue.arrayRemove([profileId])
            : FieldValue.arrayUnion([profileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.reactToMessage');
      return false;
    }
  }

  /// Pin / unpin a message.
  Future<bool> setMessagePinned(String inboxId, String messageId, bool pinned) async {
    try {
      await _messageRef(inboxId, messageId).update({'isPinned': pinned});
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.setMessagePinned');
      return false;
    }
  }

  /// Increments the thread reply count on the parent message.
  Future<void> incrementReplyCount(String inboxId, String parentMessageId) async {
    try {
      await _messageRef(inboxId, parentMessageId).update({'replyCount': FieldValue.increment(1)});
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.incrementReplyCount');
    }
  }

  /// Casts a single vote on an inline poll: removes the voter from every option
  /// then adds them to [optionIndex] (one vote per person).
  Future<bool> votePoll(String inboxId, String messageId, int optionIndex, String profileId) async {
    try {
      final ref = _messageRef(inboxId, messageId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>?;
        if (data == null) return;
        final poll = Map<String, dynamic>.from(data['pollData'] ?? {});
        final votes = Map<String, dynamic>.from(poll['votes'] ?? {});
        votes.updateAll((k, v) => (List<String>.from(v ?? []))..remove(profileId));
        final key = optionIndex.toString();
        votes[key] = (List<String>.from(votes[key] ?? []))..add(profileId);
        poll['votes'] = votes;
        tx.update(ref, {'pollData': poll});
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.votePoll');
      return false;
    }
  }


  @override
  Future<bool> inboxExists(String inboxId) async {
    AppConfig.logger.d("");

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxId).get();
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
    AppConfig.logger.t("Retrieving messages for inbox room $inboxId from firestore");
    List<InboxMessage> messages = [];

    try {
      QuerySnapshot querySnapshot = await inboxReference.doc(inboxId)
          .collection(AppFirestoreCollectionConstants.messages)
          .orderBy(AppFirestoreConstants.createdTime).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var messageSnapshot in querySnapshot.docs) {
          final data = messageSnapshot.data();
          if (data == null) continue;
          InboxMessage message = InboxMessage.fromJSON(data as Map<String, dynamic>);
          message.id = messageSnapshot.id;
          AppConfig.logger.t('Message text ${message.text}');
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
    AppConfig.logger.d("");

    try {
      await inboxReference.doc(inbox.id).set(inbox.toJSON());
      AppConfig.logger.d("");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.addInbox');
    }

    return false;
  }

  @override
  Future<List<Inbox>> getProfileInbox(String profileId) async {
    AppConfig.logger.t("Getting Inbox for Profile $profileId from firestore");

    List<Inbox> inboxs = [];

    try {
      // OPTIMIZED: Added limit to prevent loading too many conversations
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: profileId)
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
    AppConfig.logger.d("Getting or creating InboxRoom for profile ${profile.id}");

    Inbox inbox = Inbox();

    String inboxRoomId = "${profile.id}_${itemmate.id}";
    String mateInboxRoomId = "${itemmate.id}_${profile.id}";

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxRoomId).get();
      if(documentSnapshot.exists){
        AppConfig.logger.d("Retrieving inbox from main user");
        final data = documentSnapshot.data();
        if (data != null) {
          inbox = Inbox.fromJSON(data as Map<String, dynamic>);
          inbox.id = documentSnapshot.id;
        }
      } else {
        DocumentSnapshot itemmateDocumentSnapshot = await inboxReference.doc(mateInboxRoomId).get();
        if(itemmateDocumentSnapshot.exists){
          AppConfig.logger.i("Retrieving inbox from itemmate");
          final itemmateData = itemmateDocumentSnapshot.data();
          if (itemmateData != null) {
            inbox = Inbox.fromJSON(itemmateData as Map<String, dynamic>);
            inbox.id = documentSnapshot.id;
          }
        } else {
          AppConfig.logger.i("Creating inbox from main user");
          inbox.id = inboxRoomId;
          List<String> profileIds = [];
          profileIds.add(profile.id);
          profileIds.add(itemmate.id);
          inbox.profileIds = profileIds;

          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
        }
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.getOrCreateInboxRoom');
      
      // Fallback for offline mesh swarm:
      // Construct the inbox room ID locally if Firestore is unreachable,
      // allowing active swarm peers to engage in messaging.
      inbox.id = inboxRoomId;
      inbox.profileIds = [profile.id, itemmate.id];
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
    AppConfig.logger.t("Iniciando stream de mensajes para: $inboxId (limit: $limit)");

    return inboxReference
        .doc(inboxId)
        .collection(AppFirestoreCollectionConstants.messages)
        .orderBy(AppFirestoreConstants.createdTime, descending: true) // Most recent first
        .limit(limit) // Limit to reduce Firestore reads
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
          inbox = Inbox.fromJSON(data as Map<String, dynamic>);
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
          inbox = Inbox.fromJSON(data as Map<String, dynamic>);
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
          inbox = Inbox.fromJSON(data as Map<String, dynamic>);
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
    try {
      await inboxReference.doc(roomId).set(data, SetOptions(merge: true));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'InboxFirestore.setSupportHandoff');
    }
  }

  /// Live queue of support threads that need a human agent (Atención al
  /// Cliente), most recently active first.
  Stream<List<Inbox>> streamSupportQueue() {
    return inboxReference
        .where('isSupportRoom', isEqualTo: true)
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
    return inboxReference
        .where('isSupportRoom', isEqualTo: true)
        .limit(limit)
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
    return inboxReference.doc(roomId).collection(AppFirestoreCollectionConstants.roomProfiles)
        .doc(profileId).snapshots().map((doc) => InboxProfileInfo.fromJSON(doc.data() ?? {}));
  }

  /// OPTIMIZED: Obtiene el conteo de mensajes sin leer para un perfil.
  /// Un mensaje se considera no leído si:
  /// - El lastMessage.ownerId != profileId (no es del usuario actual)
  /// - El lastMessage.seenTime == 0 (no ha sido visto)
  Future<int> getUnreadInboxCount(String profileId) async {
    AppConfig.logger.t("Getting unread inbox count for profile $profileId");
    int unreadCount = 0;

    try {
      // OPTIMIZED: Added limit and orderBy to reduce reads - only check most recent conversations
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: profileId)
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
                inbox.lastMessage!.ownerId != profileId &&
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
  Future<void> setLastTyping(String roomId, String profileId) {
    return inboxReference.doc(roomId)
        .collection(AppFirestoreCollectionConstants.roomProfiles)
        .doc(profileId).set({
          AppFirestoreConstants.lastTyping: DateTime.now().millisecondsSinceEpoch,
        });
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
