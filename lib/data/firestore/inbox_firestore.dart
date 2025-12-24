import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/inbox.dart';
import '../../domain/model/inbox_message.dart';
import '../../domain/model/inbox_profile_info.dart';
import '../../domain/repository/inbox_repository.dart';

import '../../utils/constants/core_constants.dart';
import '../../utils/enums/inbox_room_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

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
    } catch (e) {
      AppConfig.logger.e("Something occurred.");
    }

    AppConfig.logger.d("Message not send");
    return false;
  }

  @override
  Future<bool> handleLikeMessage(String profileId, String messageId, bool isLiked) async {
    AppConfig.logger.d("");
    try {
      await messageReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == messageId) {
            isLiked ? await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([profileId])})
                : await document.reference.update({AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([profileId])});
          }
        }
      });

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
          InboxMessage message = InboxMessage.fromJSON(messageSnapshot.data());
          message.id = messageSnapshot.id;
          AppConfig.logger.t('Message text ${message.text}');
          messages.add(message);
        }
        AppConfig.logger.t("${messages.length} messages retrieved");
      } else {
        AppConfig.logger.t("No messages found Found");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<List<Inbox>> getProfileInbox(String profileId) async {
    AppConfig.logger.t("Getting Inbox for Profile $profileId from firestore");

    List<Inbox> inboxs = [];

    try {
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: profileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for(var documentSnapshot in querySnapshot.docs) {          
          Inbox inbox = Inbox.fromJSON(documentSnapshot.data());
          inbox.id = documentSnapshot.id;

            AppConfig.logger.i('Inbox ${inbox.id} found');
            inboxs.add(inbox);
          }
        }
      AppConfig.logger.i("${inboxs.length} inboxRoom retrieved");
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
        inbox = Inbox.fromJSON(documentSnapshot.data());
        inbox.id = documentSnapshot.id;
      } else {
        DocumentSnapshot itemmateDocumentSnapshot = await inboxReference.doc(mateInboxRoomId).get();
        if(itemmateDocumentSnapshot.exists){
          AppConfig.logger.i("Retrieving inbox from itemmate");
          inbox = Inbox.fromJSON(itemmateDocumentSnapshot.data());
          inbox.id = documentSnapshot.id;
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

    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
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
  Stream<List<InboxMessage>> messageStream(String inboxId) {
    AppConfig.logger.t("Iniciando stream de mensajes para: $inboxId");

    return inboxReference
        .doc(inboxId)
        .collection(AppFirestoreCollectionConstants.messages)
        .orderBy(AppFirestoreConstants.createdTime, descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        InboxMessage message = InboxMessage.fromJSON(doc.data());
        message.id = doc.id;
        return message;
      }).toList();
    });
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
        inbox = Inbox.fromJSON(documentSnapshot.data());
        inbox.id = documentSnapshot.id;
        
      } else {
        AppConfig.logger.d("Creating inbox for AppBot");
        inbox.id = inboxRoomId;
        List<String> profileIds = [];
        profileIds.add(profileId);
        inbox.profileIds = profileIds;
          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d(inbox.toString());
    return inbox;
  }

  @override
  Stream<InboxProfileInfo> getInboxProfileInfo(String roomId, String profileId) {
    return inboxReference.doc(roomId).collection(AppFirestoreCollectionConstants.profiles)
        .doc(profileId).snapshots().map((doc) => InboxProfileInfo.fromJSON(doc.data() ?? {}));
  }

  @override
  Future<void> setLastTyping(String roomId, String profileId) {
    return inboxReference.doc(roomId)
        .collection(AppFirestoreCollectionConstants.profiles)
        .doc(profileId).set({
          AppFirestoreConstants.lastTyping: DateTime.now().millisecondsSinceEpoch,
        });
  }

}
