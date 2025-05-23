
import 'inbox_message.dart';


class Inbox {

  String id;
  bool isPrivate;
  InboxMessage? lastMessage;
  int createdTime;
  List<String> profileIds;

  // List<AppProfile>? profiles;
  List<InboxMessage>? messages;

  Inbox({
    this.id = "",
    this.isPrivate = true,
    this.profileIds = const [],
    this.lastMessage,
    this.createdTime = 0});


  @override
  String toString() {
    return 'Inbox{id: $id, isPrivate: $isPrivate, lastMessage: $lastMessage, createdTime: $createdTime, profileIds: $profileIds, messages: $messages}';
  }


  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'isPrivate': isPrivate,
      'lastMessage': lastMessage?.toJSON(),
      'profileIds': profileIds,
      'createdTime': createdTime
    };
  }

  Inbox.fromJSON(data) :
        id = data["id"] ?? "",
        isPrivate = data["isPrivate"] ?? true,
        profileIds = List.from(data["profileIds"] ?? []),
        lastMessage = data["lastMessage"] == null ? InboxMessage()
            : InboxMessage.fromJSON(data["lastMessage"] ?? <dynamic, dynamic>{}),
        createdTime = data["createdTime"] ?? 0;

  ///DEPRECATED
  // Inbox.fromDocumentSnapshot(DocumentSnapshot documentSnapshot):
  //   id = documentSnapshot.id,
  //   isPrivate = documentSnapshot.get("isPrivate") ?? true,
  //   profileIds = List.from(documentSnapshot.get("profileIds") ?? []),
  //   lastMessage = documentSnapshot.get("lastMessage") == null ? InboxMessage()
  //       : InboxMessage.fromJSON(documentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
  //   createdTime = documentSnapshot.get("createdTime") ?? 0;

  ///DEPRECATED
  // Inbox.fromQueryDocumentSnapshot(QueryDocumentSnapshot queryDocumentSnapshot):
  //   id = queryDocumentSnapshot.id,
  //   isPrivate = queryDocumentSnapshot.get("isPrivate") ?? true,
  //   profileIds = List.from(queryDocumentSnapshot.get("profileIds") ?? []),
  //   lastMessage = queryDocumentSnapshot.get("lastMessage") == null ? InboxMessage()
  //       : InboxMessage.fromJSON(queryDocumentSnapshot.get("lastMessage") ?? <dynamic, dynamic>{}),
  //   createdTime = queryDocumentSnapshot.get("createdTime") ?? 0;



}
