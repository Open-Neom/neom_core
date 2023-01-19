
class Hashtag {

  String id;
  List<String> postIds;
  int createdTime;

  Hashtag({
      this.id = "",
      this.postIds = const [],
      this.createdTime = 0,
  });

  @override
  String toString() {
    return 'Hashtag{id: $id, postIds: $postIds, createdTime: $createdTime}';
  }


  Hashtag.fromJSON(Map<dynamic, dynamic> data) :
    id = data["id"],
    postIds = List.from(data["postIds"]),
    createdTime = data["createdTime"];


  Map<String, dynamic> toJSON()=> {
    'id': id,
    'postIds': postIds,
    'createdTime': createdTime
  };

}
