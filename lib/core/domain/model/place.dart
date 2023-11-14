import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_flavour.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/place_type.dart';
import 'address.dart';
import 'place_commodity.dart';
import 'price.dart';

class Place {

  String id = "";
  String name = "";
  String description = "";
  String ownerName = "";
  String ownerId = "";
  String ownerImgUrl = "";
  PlaceType type;
  Address? address;
  double reviewStars =  0.0;
  Price? price =  Price();
  PlaceCommodity? placeCommodity;
  Position? position;
  bool isActive = true;
  bool isMain = true;

  List<String> galleryImgUrls = [];
  List<String> bookings = [];
  List<String> reviews = [];

  Place({
    this.id = "",
    this.name = "",
    this.description = "",
    this.ownerName = "",
    this.ownerId = "",
    this.ownerImgUrl = "",
    this.type = PlaceType.publicSpace,
    this.address,
    this.reviewStars =  0.0,
    this.price,
    this.placeCommodity,
    this.position,
    this.isActive = true,
    this.isMain = true,
    this.galleryImgUrls = const [],
    this.bookings = const [],
    this.reviews = const []
  });


  @override
  String toString() {
    return 'Place{id: $id, name: $name, description: $description, ownerName: $ownerName, ownerId: $ownerId, ownerImgUrl: $ownerImgUrl, type: $type, address: $address, reviewStars: $reviewStars, price: $price, placeCommodity: $placeCommodity, position: $position, isActive: $isActive, isMain: $isMain, galleryImgUrls: $galleryImgUrls, bookings: $bookings, reviews: $reviews}';
  }

  Map<String, dynamic> toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'ownerName': ownerName,
    'ownerId': ownerId,
    'ownerImgUrl': ownerImgUrl,
    'type': type.name,
    'address': address?.toJSON() ?? Address().toJSON(),
    'reviewStars': reviewStars,
    'price': price?.toJSON() ?? Price().toJSON(),
    'placeCommodity': placeCommodity?.toJSON() ?? PlaceCommodity().toJSON(),
    'position': jsonEncode(position),
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
    'placeCommodity': placeCommodity,
    'galleryImgUrls': galleryImgUrls,
    'reviews': reviews,
  };

  Place.fromJSON(data):
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    address = Address.fromJSON(data["address"] ?? {}),
    ownerName = data["ownerName"] ?? "",
    ownerId = data["ownerId"] ?? "",
    ownerImgUrl = data["ownerImgUrl"] ?? AppFlavour.getNoImageUrl(),
    position = CoreUtilities.JSONtoPosition(data["position"]),
    type = EnumToString.fromString(PlaceType.values, data["type"] ?? PlaceType.publicSpace.name) ?? PlaceType.publicSpace,
    galleryImgUrls = data["galleryImgUrls"]?.cast<String>() ?? [],
    bookings = data["bookings"]?.cast<String>() ?? [],
    reviews = data["reviews"]?.cast<String>() ?? [],
    reviewStars = double.parse(data["reviewStars"]?.toString() ?? "10"),
    price = Price.fromJSON(data["price"] ?? {}),
    placeCommodity = PlaceCommodity.fromJSON(data["placeCommodity"] ?? {}),
    isActive = data["isActive"] ?? false,
    isMain = data["isMain"] ?? false;

  Place.addBasic(this.type);

}
