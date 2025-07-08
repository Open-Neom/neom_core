import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/vocal_type.dart';
import 'instrument.dart';

class InstrumentFulfillment {

  String id;
  String profileName;
  String profileImgUrl;
  String profileId;
  Instrument instrument;
  VocalType vocalType;
  bool isFulfilled;


  InstrumentFulfillment({
    required this.id,
    required this.instrument,
    this.isFulfilled = false,
    this.profileId = "",
    this.profileImgUrl = "",
    this.profileName = "",
    this.vocalType = VocalType.none
  });


  Map<String, dynamic> toJSON() =>{
      'id': id,
      'instrument': instrument.toJSON(),
      'isFulfilled': isFulfilled,
      'profileId': profileId,
      'profileImgUrl': profileImgUrl,
      'profileName': profileName,
      'vocalType': vocalType.name,
  };


  InstrumentFulfillment.fromJSON(Map<dynamic, dynamic> data) :
    id = data["id"] ?? 0,
    instrument = Instrument.fromJSON(data["instrument"]),
    isFulfilled = data["isFulfilled"] ?? "",
    profileId = data["profileId"] ?? "",
    profileImgUrl = data["profileImgUrl"] ?? "",
    profileName = data["profileName"] ?? "",
    vocalType = EnumToString.fromString(VocalType.values, data["vocalType"] ?? "none") ?? VocalType.none;

}
