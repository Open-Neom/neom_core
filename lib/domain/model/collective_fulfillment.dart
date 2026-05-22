
class CollectiveFulfillment {

  String collectiveName;
  String collectiveImgUrl;
  String collectiveId;
  bool hasAccepted;

  CollectiveFulfillment({
    this.collectiveId = "",
    this.collectiveImgUrl = "",
    this.collectiveName = "",
    this.hasAccepted = false,
  });


  Map<String, dynamic> toJSON() =>{
    'collectiveId': collectiveId,
    'collectiveImgUrl': collectiveImgUrl,
    'collectiveName': collectiveName,
    'hasAccepted': hasAccepted,
  };


  CollectiveFulfillment.fromJSON(Map<dynamic, dynamic> data) :
    hasAccepted = data["hasAccepted"] ?? false,
    collectiveId = data["collectiveId"] ?? "",
    collectiveImgUrl = data["collectiveImgUrl"] ?? "",
    collectiveName = data["collectiveName"] ?? "";

}
