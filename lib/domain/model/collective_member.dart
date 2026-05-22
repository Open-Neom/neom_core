import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/collective_member_role.dart';
import '../../utils/enums/vocal_type.dart';
import 'instrument.dart';

class CollectiveMember {

  String id = "";
  String name = "";
  String imgUrl = "";
  String profileId = "";
  Instrument? instrument;
  VocalType vocalType = VocalType.none;
  CollectiveMemberRole role = CollectiveMemberRole.member;
  bool isMuted = true;

  CollectiveMember({
    this.id = "",
    this.name = "",
    this.imgUrl = "",
    this.profileId = "",
    this.instrument ,
    this.vocalType = VocalType.none,
    this.role = CollectiveMemberRole.member,
    this.isMuted = true
  });

  @override
  String toString() {
    return 'CollectiveMember{id: $id, name: $name, imgUrl: $imgUrl, profileId: $profileId, instrument: $instrument, vocalType: $vocalType, role: $role, isMuted: $isMuted}';
  }

  @override
  bool operator ==(Object other) =>
      other is CollectiveMember &&
          name == other.name &&
          imgUrl == other.imgUrl &&
          profileId == other.profileId &&
          instrument?.name == other.instrument?.name &&
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

  CollectiveMember.fromJSON(dynamic data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        imgUrl = data["imgUrl"] ?? "",
        profileId = data["profileId"] ?? "",
        instrument = Instrument.fromJSON(data["instrument"] ?? {}),
        vocalType = EnumToString.fromString(VocalType.values, data["vocalType"] ?? VocalType.none.name) ?? VocalType.none,
        role = EnumToString.fromString(CollectiveMemberRole.values, data["role"] ?? CollectiveMemberRole.member.name) ?? CollectiveMemberRole.member,
        isMuted = data["isMuted"] ?? true;

}
