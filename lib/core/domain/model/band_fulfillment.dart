
class BandFulfillment {

  String bandName;
  String bandImgUrl;
  String bandId;
  bool hasAccepted;

  BandFulfillment({
    this.bandId = "",
    this.bandImgUrl = "",
    this.bandName = "",
    this.hasAccepted = false,
  });


  Map<String, dynamic> toJSON() =>{
    'bandId': bandId,
    'bandImgUrl': bandImgUrl,
    'bandName': bandName,
    'hasAccepted': hasAccepted,
  };


  BandFulfillment.fromJSON(Map<dynamic, dynamic> data) :
    hasAccepted = data["hasAccepted"] ?? "",
    bandId = data["bandId"] ?? "",
    bandImgUrl = data["bandImgUrl"] ?? "",
    bandName = data["bandName"] ?? "";

}
