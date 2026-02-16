import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/core_utilities.dart';
import '../../utils/enums/event_status.dart';
import '../../utils/enums/event_type.dart';
import '../../utils/enums/usage_reason.dart';
import 'app_media_item.dart';
import 'band_fulfillment.dart';
import 'instrument_fulfillment.dart';
import 'place.dart';
import 'price.dart';

class Event {

  String id;
  String name;
  String description;
  String imgUrl;
  String coverImgUrl;

  String ownerId;
  String ownerName;
  String ownerEmail;

  bool public;

  int createdTime;
  int eventDate;

  UsageReason reason;

  List<String>? genres;

  double itemPercentageCoverage; ///MINIMUM % COVERAGE TO ALLOW SEND REQUEST
  int distanceKm; ///MAXIMUM DISTANCE TO ALLOW SENDING REQUEST


  Price? paymentPrice; ///PAYMENT FOR ARTISTS
  Price? coverPrice; ///COVER PRICE FOR CASUALS

  EventType type;
  EventStatus status;
  bool isFulfilled = false;

  Place? place;
  Position? position; //Event position from profile.position

  List<AppMediaItem>? appMediaItems;
  List<InstrumentFulfillment>? instrumentsFulfillment;
  List<BandFulfillment>? bandsFulfillment;
  List<String>? watchingProfiles;
  List<String>? goingProfiles;
  int guestsLimit;
  bool isOnline;
  String? url;
  bool isOutdoor;
  bool isTest;
  
  Event({
      this.id = "",
      this.name = "",
      this.description = "",
      this.imgUrl = "",
      this.coverImgUrl = "",
      this.ownerId = '',
      this.ownerName = '',
      this.ownerEmail = '',
      this.public = true,
      this.createdTime = 0,
      this.eventDate = 0,
      this.reason = UsageReason.any,
      this.genres,
      this.itemPercentageCoverage = 0.0,
      this.distanceKm = 0,
      this.paymentPrice,
      this.coverPrice,
      this.type = EventType.rehearsal,
      this.status = EventStatus.draft,
      this.place,
      this.position,
      this.isFulfilled = false,
      this.appMediaItems,
      this.instrumentsFulfillment,
      this.bandsFulfillment,
      this.watchingProfiles,
      this.goingProfiles,
      this.isOnline = false,
      this.url,
      this.isOutdoor = false,
      this.isTest = false,
      this.guestsLimit = 0
  });

  @override
  String toString() {
    return 'Event{id: $id, name: $name, description: $description, imgUrl: $imgUrl, coverImgUrl: $coverImgUrl, ownerId: $ownerId, ownerName: $ownerName, ownerEmail: $ownerEmail, public: $public, createdTime: $createdTime, eventDate: $eventDate, reason: $reason, genres: $genres, itemPercentageCoverage: $itemPercentageCoverage, distanceKm: $distanceKm, paymentPrice: $paymentPrice, coverPrice: $coverPrice, type: $type, status: $status, isFulfilled: $isFulfilled, place: $place, position: $position, appMediaItems: $appMediaItems, instrumentsFulfillment: $instrumentsFulfillment, bandsFulfillment: $bandsFulfillment, watchingProfiles: $watchingProfiles, goingProfiles: $goingProfiles, guestsLimit: $guestsLimit, isOnline: $isOnline, isTest: $isTest}';
  }

  Event.createBasic(this.name, desc):
    id = "",
    description = desc,
    imgUrl = "",
    coverImgUrl = "",
    ownerId = '',
    ownerName = '',
    ownerEmail = '',
    public = true,
    eventDate =  0,
    reason = UsageReason.any,
    itemPercentageCoverage = 0,
    distanceKm = 0,
    createdTime = 0,
    type = EventType.rehearsal,
    status = EventStatus.draft,
    isOnline = false,
    isOutdoor = false,
    isTest = false,
    guestsLimit = 0;

  Event.fromJSON(dynamic data):
      id = data["id"] ?? "",
      name = data["name"] ?? "",
      description = data["description"] ?? "",
      imgUrl = data["imgUrl"] ?? "",
      coverImgUrl = data['coverImgUrl'] ?? "",
      ownerId = data["ownerId"] ?? "",
      ownerName = data["ownerName"] ?? "",
      ownerEmail = data['ownerEmail'] ?? "",
      public = data["public"] ?? true,
      createdTime = data["createdTime"] ?? 0,
      eventDate = data["eventDate"] ?? 0,
      reason = EnumToString.fromString(UsageReason.values, data["reason"] ?? UsageReason.any.name) ?? UsageReason.any,
      appMediaItems = data["appMediaItems"]?.map<AppMediaItem>((item) {
        return AppMediaItem.fromJSON(item);
      }).toList() ?? [],
      genres = List.from(data["genres"]?.cast<String>() ?? []),
      itemPercentageCoverage = data["itemPercentageCoverage"] ?? 0,
      distanceKm = data["distanceKm"] ?? 0,
      paymentPrice = Price.fromJSON(data["paymentPrice"] ?? {}),
      coverPrice = Price.fromJSON(data["coverPrice"] ?? {}),
      type = EnumToString.fromString(EventType.values, data["type"] ?? EventType.rehearsal.name) ?? EventType.rehearsal,
      status = EnumToString.fromString(EventStatus.values, data["status"] ?? EventStatus.draft.name) ?? EventStatus.draft,
      position =  CoreUtilities.JSONtoPosition(data["position"]),
      place =  Place.fromJSON(data["place"] ?? {}),
      isFulfilled = data["isFulfilled"] ?? false,
      instrumentsFulfillment = data["instrumentsFulfillment"]?.map<InstrumentFulfillment>((item) {
        return InstrumentFulfillment.fromJSON(item);
      }).toList()  ?? [],
      bandsFulfillment = data["bandsFulfillment"]?.map<BandFulfillment>((item) {
        return BandFulfillment.fromJSON(item);
      }).toList() ?? [],
      watchingProfiles = List.from(data["watchingProfiles"]?.cast<String>() ?? []),
      goingProfiles = List.from(data["goingProfiles"]?.cast<String>() ?? []),
      isOnline = data["isOnline"] ?? false,
      url = data["url"],
      isOutdoor = data["isOutdoor"] ?? false,
      isTest = data["isTest"] ?? false,
      guestsLimit = data["guestsLimit"] ?? 0;

  Map<String, dynamic> toJSON() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerEmail': ownerEmail,
    'imgUrl': imgUrl,
    'coverImgUrl': coverImgUrl,
    'public': public,
    'createdTime': createdTime,
    'eventDate': eventDate,
    'reason': reason.name,
    'appMediaItems': appMediaItems?.map((appMediaItem) => appMediaItem.toJSON()).toList(),
    'genres': genres,
    'itemPercentageCoverage': itemPercentageCoverage,
    'distanceKm': distanceKm,
    'paymentPrice': paymentPrice?.toJSON() ?? Price().toJSON(),
    'coverPrice': coverPrice?.toJSON() ?? Price().toJSON(),
    'type': type.name,
    'status': status.name,
    'position': jsonEncode(position),
    'place': place?.toJSON() ?? Place().toJSON(),
    'isFulfilled': isFulfilled,
    'instrumentsFulfillment': instrumentsFulfillment?.map((instrumentFulfillment) => instrumentFulfillment.toJSON()).toList(),
    'bandsFulfillment': bandsFulfillment?.map((bandFulfillment) => bandFulfillment.toJSON()).toList(),
    'watchingProfiles': [],
    'goingProfiles': [],
    'isOnline': isOnline,
    'url': url,
    'isTest': isTest,
    'isOutdoor': isOutdoor,
    'guestsLimit': guestsLimit,
  };

}
