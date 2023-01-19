import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/constants/url_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/sponsor_type.dart';
import 'address.dart';

class Sponsor {

  String id = "";
  String name = "";
  String fullName = "";
  String phoneNumber = "";
  String countryCode = "";
  String description = "";
  String imgUrl = "";
  String ownerId = "";
  String profileId = "";
  SponsorType type;
  Address? address;
  Position? position;
  bool isActive = true;
  String externalUrl = "";
  List<String> galleryImgUrls = [];


  Sponsor({
    this.id = "",
    this.name = "",
    this.fullName = "",
    this.phoneNumber = "",
    this.countryCode = "",
    this.description = "",
    this.ownerId = "",
    this.profileId = "",
    this.imgUrl = "",
    this.type = SponsorType.publicSpace,
    this.address,
    this.position,
    this.isActive = true,
    this.externalUrl = "",
    this.galleryImgUrls = const []
  });


  @override
  String toString() {
    return 'Sponsor{id: $id, name: $name, fullName: $fullName, phoneNumber: $phoneNumber, countryCode: $countryCode, description: $description, imgUrl: $imgUrl, ownerId: $ownerId, profileId: $profileId, type: $type, address: $address, position: $position, isActive: $isActive, externalUrl: $externalUrl, galleryImgUrls: $galleryImgUrls}';
  }


  Map<String, dynamic> toJSON()=>{
    'name': name,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'description': description,
    'ownerId': ownerId,
    'imgUrl': imgUrl,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'isActive': isActive,
    'galleryImgUrls': galleryImgUrls
  };


  Map<String, dynamic> toJSONSimple()=>{
    'name': name,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'description': description,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'galleryImgUrls': galleryImgUrls,
  };

  Sponsor.fromJSON(data):
    name = data["name"] ?? "",
    fullName = data["fullName"] ?? "",
    phoneNumber = data["phoneNumber"] ?? "",
    countryCode = data["countryCode"] ?? "",
    description = data["description"] ?? "",
    address = Address.fromJSON(data["address"]),
    ownerId = data["ownerId"] ?? "",
    profileId = data["ownerId"] ?? "",
    imgUrl = data["imgUrl"] ?? UrlConstants.noImageUrl,
    position = CoreUtilities.JSONtoPosition(data["position"]),
    type = EnumToString.fromString(SponsorType.values, data["type"] ?? SponsorType.publicSpace.name) ?? SponsorType.publicSpace,
    galleryImgUrls = data["galleryImgUrls"].cast<String>() ?? [];

}
