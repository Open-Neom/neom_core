import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_properties.dart';
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
  String profileId = ""; ///Sponsor Profile Id if on app.
  String imgUrl = "";
  String ownerId = ""; ///WHO CREATED THIS SPONSOR ADMIN PURPOSES
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
    'profileId': profileId,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'isActive': isActive,
    'externalUrl': externalUrl,
    'galleryImgUrls': galleryImgUrls
  };


  Map<String, dynamic> toJSONSimple()=>{
    'name': name,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'description': description,
    'type': type.name,
    'externalUrl': externalUrl,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'isActive': isActive,
    'galleryImgUrls': galleryImgUrls,
  };

  Sponsor.fromJSON(dynamic data):
    name = data["name"] ?? "",
    fullName = data["fullName"] ?? "",
    phoneNumber = data["phoneNumber"] ?? "",
    countryCode = data["countryCode"] ?? "",
    description = data["description"] ?? "",
    profileId = data["ownerId"] ?? "",
    imgUrl = data["imgUrl"] ?? AppProperties.getNoImageUrl(),
    ownerId = data["ownerId"] ?? "",
    type = EnumToString.fromString(SponsorType.values, data["type"] ?? SponsorType.publicSpace.name) ?? SponsorType.publicSpace,
    address = Address.fromJSON(data["address"]),
    position = CoreUtilities.JSONtoPosition(data["position"]),
    isActive = data["isActive"] ?? true,
    externalUrl = data["externalUrl"] ?? "",
    galleryImgUrls = data["galleryImgUrls"].cast<String>() ?? [];

}
