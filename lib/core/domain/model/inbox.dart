import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_profile.dart';
import 'inbox_message.dart';


class Inbox {

  String id;
  bool isPrivate;
  InboxMessage? lastMessage;
  int createdTime;
  List<String> profileIds;

  List<AppProfile>? profiles;
  List<InboxMessage>? messages;

  Inbox({
    this.id = "",
    this.isPrivate = true,
    this.profileIds = const [],
    this.lastMessage,
    this.createdTime = 0});


  @override
  String toString() {
    return 'Inbox{id: $id, isPrivate: $isPrivate, lastMessage: $lastMessage, createdTime: $createdTime, profileIds: $profileIds, profiles: $profiles, messages: $messages}';
  }


  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'isPrivate': isPrivate,
      'lastMessage': lastMessage,
      'profileIds': profileIds,
      'createdTime': createdTime
    };
  }


  Inbox.fromDocumentSnapshot(DocumentSnapshot documentSnapshot):
    id = documentSnapshot.id,
    isPrivate = documentSnapshot.get("isPrivate") ?? true,
    profileIds = List.from(documentSnapshot.get("profileIds") ?? []),
    lastMessage = documentSnapshot.get("lastMessage") == null ? InboxMessage()
        : InboxMessage.fromJSON(documentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
    createdTime = documentSnapshot.get("createdTime") ?? 0;


  Inbox.fromQueryDocumentSnapshot(QueryDocumentSnapshot queryDocumentSnapshot):
    id = queryDocumentSnapshot.id,
    isPrivate = queryDocumentSnapshot.get("isPrivate") ?? true,
    profileIds = List.from(queryDocumentSnapshot.get("profileIds") ?? []),
    lastMessage = queryDocumentSnapshot.get("lastMessage") == null ? InboxMessage()
        : InboxMessage.fromJSON(queryDocumentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
    createdTime = queryDocumentSnapshot.get("createdTime") ?? 0;

}
