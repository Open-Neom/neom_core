import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/model/inbox.dart';
import '../../domain/model/inbox_message.dart';
import '../../domain/repository/inbox_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/enums/inbox_room_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class InboxFirestore implements InboxRepository {
  
  final inboxReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.inbox);
  final messageReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.messages);
  //final activityFeedReference = FirebaseFirestore.instance.collection(GigConstants.fs_feed);

  @override
  Future<bool> addMessage(String inboxRoomId, InboxMessage message,
      {InboxRoomType inboxRoomType = InboxRoomType.profile}) async {
    AppUtilities.logger.t("Adding Message to inbox $inboxRoomId");

    try {
      await inboxReference.doc(inboxRoomId).collection(AppFirestoreCollectionConstants.messages)
          .add(message.toJSON());
      AppUtilities.logger.d("${message.text} message added");

      if(inboxRoomType == InboxRoomType.profile) {
        await inboxReference.doc(inboxRoomId)
            .update({AppFirestoreConstants.lastMessage: message.toJSON()});
      }

      AppUtilities.logger.i("${message.text} last message added");
      return true;
    } catch (e) {
      AppUtilities.logger.e("Something occurred.");
    }

    AppUtilities.logger.d("Message not send");
    return false;
  }

  @override
  Future<bool> handleLikeMessage(String profileId, String messageId, bool isLiked) async {
    AppUtilities.logger.d("");
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
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<bool> inboxExists(String inboxId) async {
    AppUtilities.logger.d("");

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxId).get();
      if(documentSnapshot.exists){
        return true;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("");
    return false;
  }


  @override
  Future<List<InboxMessage>> retrieveMessages(String inboxId) async {
    AppUtilities.logger.t("Retrieving messages for inbox room $inboxId from firestore");
    List<InboxMessage> messages = [];

    try {
      QuerySnapshot querySnapshot = await inboxReference.doc(inboxId)
          .collection(AppFirestoreCollectionConstants.messages)
          .orderBy(AppFirestoreConstants.createdTime).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var messageSnapshot in querySnapshot.docs) {
          InboxMessage message = InboxMessage.fromJSON(messageSnapshot.data());
          message.id = messageSnapshot.id;
          AppUtilities.logger.t('Message text ${message.text}');
          messages.add(message);
        }
        AppUtilities.logger.t("${messages.length} messages retrieved");
      } else {
        AppUtilities.logger.t("No messages found Found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return messages;
  }


  @override
  Future<bool> addInbox(Inbox inbox) async {
    AppUtilities.logger.d("");

    try {
      await inboxReference.doc(inbox.id).set(inbox.toJSON());
      AppUtilities.logger.d("");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<List<Inbox>> getProfileInbox(String profileId) async {
    AppUtilities.logger.t("Getting Inbox for Profile $profileId from firestore");

    List<Inbox> inboxs = [];

    try {
      QuerySnapshot querySnapshot = await inboxReference
          .where(AppFirestoreConstants.profileIds, arrayContains: profileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for(var documentSnapshot in querySnapshot.docs) {          
          Inbox inbox = Inbox.fromJSON(documentSnapshot.data());
          inbox.id = documentSnapshot.id;

          ///DEPRECATED
          // inbox.profiles = [];
          // for (String itemmateId in inbox.profileIds) {
          //   AppProfile mate = AppProfile();
          //   if(itemmateId != profileId) {
          //     if(inbox.lastMessage?.ownerId != profileId) {
          //       mate.id = inbox.lastMessage!.ownerId;
          //       mate.name = inbox.lastMessage!.profileName;
          //       mate.photoUrl = inbox.lastMessage!.profileImgUrl;
          //     } else {
          //       //mate =  await GigProfileFirestore().retrieveGigProfileSimple(itemmateId);
          //     }
          //
          //     inbox.profiles!.add(mate);
          //   } else if (inbox.profileIds.length == 1) {
          //     mate = AppProfile(
          //       name: AppConstants.appBotName,
          //       photoUrl: AppFlavour.getAppLogoUrl()
          //     );
          //
          //     inbox.profiles!.add(mate);
          //   }
          // }

            AppUtilities.logger.i('Inbox ${inbox.id} found');
            inboxs.add(inbox);
          }
        }
      AppUtilities.logger.i("${inboxs.length} inboxRoom retrieved");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return inboxs;
  }


  @override
  Future<Inbox> getOrCreateInboxRoom(AppProfile profile, AppProfile itemmate) async {
    AppUtilities.logger.d("Getting or creating InboxRoom for profile ${profile.id}");

    Inbox inbox = Inbox();

    String inboxRoomId = "${profile.id}_${itemmate.id}";
    String mateInboxRoomId = "${itemmate.id}_${profile.id}";

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxRoomId).get();
      if(documentSnapshot.exists){
        AppUtilities.logger.d("Retrieving inbox from main user");
        inbox = Inbox.fromJSON(documentSnapshot.data());
        inbox.id = documentSnapshot.id;
      } else {
        DocumentSnapshot itemmateDocumentSnapshot = await inboxReference.doc(mateInboxRoomId).get();
        if(itemmateDocumentSnapshot.exists){
          AppUtilities.logger.i("Retrieving inbox from itemmate");          
          inbox = Inbox.fromJSON(itemmateDocumentSnapshot.data());
          inbox.id = documentSnapshot.id;
        } else {
          AppUtilities.logger.i("Creating inbox from main user");
          inbox.id = inboxRoomId;
          List<String> profileIds = [];
          profileIds.add(profile.id);
          profileIds.add(itemmate.id);
          inbox.profileIds = profileIds;

          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
        }
      }

      ///DEPRECATED
      // inbox.profiles = [];
      // for(int i = 0; i < inbox.profileIds.length; i++)  {
      //   String itemmateId = inbox.profileIds.elementAt(i);
      //   if(itemmateId != profile.id) {
      //     AppProfile itemmate = await ProfileFirestore().retrieve(itemmateId);
      //     inbox.profiles!.add(itemmate);
      //   }
      // }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }

    AppUtilities.logger.d(inbox.toString());
    return inbox;
  }


  @override
  void searchInboxByName(String searchField) {
    // TODO: implement searchInboxByName
    throw UnimplementedError();
  }

  @override
  Stream listenToInboxRealTime(inboxRoomId) {
    // TODO: implement listenToInboxRealTime
    throw UnimplementedError();
  }


  Future<Inbox> getOrCreateAppBotRoom(String profileId) async {
    AppUtilities.logger.t("getOrCreateAppBotRoom for profile $profileId");

    Inbox inbox = Inbox();

    String inboxRoomId = "${profileId}_${AppConstants.appBot}";

    try {
      DocumentSnapshot documentSnapshot = await inboxReference.doc(inboxRoomId).get();
      if(documentSnapshot.exists){
        AppUtilities.logger.d("Retrieving inbox from main user");
        inbox = Inbox.fromJSON(documentSnapshot.data());
        inbox.id = documentSnapshot.id;
        
      } else {
        AppUtilities.logger.d("Creating inbox for AppBot");
        inbox.id = inboxRoomId;
        List<String> profileIds = [];
        profileIds.add(profileId);
        inbox.profileIds = profileIds;
          await inboxReference.doc(inboxRoomId).set(inbox.toJSON());
      }

      // inbox.profiles = [];
      // for(int i = 0; i < inbox.profileIds.length; i++)  {
      //   String itemmateId = inbox.profileIds.elementAt(i);
      //   if(itemmateId != profileId) {
      //     AppProfile itemmate = await ProfileFirestore().retrieve(itemmateId);
      //     inbox.profiles!.add(itemmate);
      //   }
      // }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d(inbox.toString());
    return inbox;
  }

}
