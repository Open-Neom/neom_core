import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/band_member_role.dart';
import '../../utils/enums/vocal_type.dart';
import 'instrument.dart';

class BandMember {

  String id = "";
  String name = "";
  String imgUrl = "";
  String profileId = "";
  Instrument? instrument;
  VocalType vocalType = VocalType.none;
  BandMemberRole role = BandMemberRole.member;
  bool isMuted = true;

  BandMember({
    this.id = "",
    this.name = "",
    this.imgUrl = "",
    this.profileId = "",
    this.instrument ,
    this.vocalType = VocalType.none,
    this.role = BandMemberRole.member,
    this.isMuted = true
  });

  @override
  String toString() {
    return 'BandMember{id: $id, name: $name, imgUrl: $imgUrl, profileId: $profileId, instrument: $instrument, vocalType: $vocalType, role: $role, isMuted: $isMuted}';
  }

  @override
  bool operator ==(Object other) =>
      other is BandMember &&
          name == other.name &&
          imgUrl == other.imgUrl &&
          profileId == other.profileId &&
          instrument!.name == other.instrument!.name &&
          vocalType == other.vocalType &&
          role == other.role &&
          isMuted == other.isMuted;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      imgUrl.hashCode ^
      profileId.hashCode ^
      instrument.hashCode ^
      vocalType.hashCode ^
      role.hashCode ^
      isMuted.hashCode;

  Map<String, dynamic> toJSON()=>{
    'name': name,
    'imgUrl': imgUrl,
    'profileId': profileId,
    'instrument': instrument?.toJSON() ?? Instrument().toJSON(),
    'vocalType': vocalType.name,
    'role': role.name,
    'isMuted': isMuted,
  };

  BandMember.fromQueryDocumentSnapshot(QueryDocumentSnapshot queryDocumentSnapshot) :
        id = queryDocumentSnapshot.id,
        name = queryDocumentSnapshot.get("name"),
        imgUrl = queryDocumentSnapshot.get("imgUrl"),
        profileId = queryDocumentSnapshot.get("profileId"),
        instrument = Instrument.fromJSON(queryDocumentSnapshot.get("instrument")),
        vocalType = EnumToString.fromString(VocalType.values, queryDocumentSnapshot.get("vocalType"))!,
        role = EnumToString.fromString(BandMemberRole.values, queryDocumentSnapshot.get("role"))!,
        isMuted = queryDocumentSnapshot.get("isMuted");


}
