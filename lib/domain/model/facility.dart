import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_properties.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/facilitator_type.dart';
import 'address.dart';
import 'facility_commodity.dart';
import 'price.dart';

class Facility {

  String id = "";
  String name = "";
  String description = "";
  String ownerName = "";
  String ownerId = "";
  String ownerImgUrl = "";
  FacilityType type;
  Address? address;
  double reviewStars =  0.0;
  Price? price =  Price();
  FacilityCommodity? facilityCommodity;
  Position? position;
  bool isActive = true;
  bool isMain = true;

  List<String> galleryImgUrls = [];
  List<String> bookings = [];
  List<String> reviews = [];

  Facility({
    this.id = "",
    this.name = "",
    this.description = "",
    this.ownerName = "",
    this.ownerId = "",
    this.ownerImgUrl = "",
    this.type = FacilityType.publisher,
    this.address,
    this.reviewStars =  0.0,
    this.price,
    this.facilityCommodity,
    this.position,
    this.isActive = true,
    this.isMain = true,
    this.galleryImgUrls = const [],
    this.bookings = const [],
    this.reviews = const []
  });


  @override
  String toString() {
    return 'Facility{id: $id, name: $name, description: $description, ownerName: $ownerName, ownerId: $ownerId, ownerImgUrl: $ownerImgUrl, type: $type, address: $address, reviewStars: $reviewStars, price: $price, facilityCommodity: $facilityCommodity, position: $position, isActive: $isActive, isMain: $isMain, galleryImgUrls: $galleryImgUrls, bookings: $bookings, reviews: $reviews}';
  }

  Facility.fromQueryDocumentSnapshot({required QueryDocumentSnapshot queryDocumentSnapshot}):
    id = queryDocumentSnapshot.id,
    name = queryDocumentSnapshot.get("name"),
    description = queryDocumentSnapshot.get("description"),
    ownerName = queryDocumentSnapshot.get("ownerName"),
    ownerId = queryDocumentSnapshot.get("ownerId"),
    ownerImgUrl = queryDocumentSnapshot.get("ownerImgUrl"),
    type = EnumToString.fromString(FacilityType.values, queryDocumentSnapshot.get("type")) ?? FacilityType.publisher,
    address = Address.fromJSON(queryDocumentSnapshot.get("address")),
    reviewStars = queryDocumentSnapshot.get("reviewStars"),
    price = Price.fromJSON(queryDocumentSnapshot.get("price")),
    facilityCommodity = FacilityCommodity.fromJSON(queryDocumentSnapshot.get("facilityCommodity")),
    position= CoreUtilities.JSONtoPosition(queryDocumentSnapshot.get("position")),
    isActive = queryDocumentSnapshot.get("isActive"),
    isMain = queryDocumentSnapshot.get("isMain"),
    galleryImgUrls = List.from(queryDocumentSnapshot.get("galleryImgUrls") ?? []),
    bookings = List.from(queryDocumentSnapshot.get("bookings") ?? []),
    reviews = List.from(queryDocumentSnapshot.get("reviews"));


  Map<String, dynamic> toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'ownerName': ownerName,
    'ownerId': ownerId,
    'ownerImgUrl': ownerImgUrl,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'reviewStars': reviewStars,
    'price': price?.toJSON() ?? Price().toJSON(),
    'facilityCommodity': facilityCommodity?.toJSON() ?? FacilityCommodity().toJSON(),
    'isActive': isActive,
    'isMain': isMain,
    'galleryImgUrls': galleryImgUrls,
    'bookings': bookings,
    'reviews': reviews,
  };

  Map<String, dynamic> toJSONSimple()=>{
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'position': jsonEncode(position),
    'reviewStars': reviewStars,
    'price': price,
    'placeCommodity': facilityCommodity,
    'galleryImgUrls': galleryImgUrls,
    'reviews': reviews,
  };

  Facility.fromJSON(dynamic data):
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    address = Address.fromJSON(data["address"]),
    ownerName = data["ownerName"] ?? "",
    ownerId = data["ownerId"] ?? "",
    ownerImgUrl = data["ownerImgUrl"] ?? AppProperties.getNoImageUrl(),
    position = CoreUtilities.JSONtoPosition(data["position"]),
    type = EnumToString.fromString(FacilityType.values, data["type"] ?? "producer") ?? FacilityType.publisher,
    galleryImgUrls = data["galleryImgUrls"].cast<String>() ?? [],
    bookings = data["bookings"].cast<String>() ?? [],
    reviews = data["reviews"]?.cast<String>() ?? [];

  Facility.addBasic(this.type);


}
