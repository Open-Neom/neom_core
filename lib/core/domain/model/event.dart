import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/event_status.dart';
import '../../utils/enums/event_type.dart';
import '../../utils/enums/usage_reason.dart';
import 'app_item.dart';
import 'app_profile.dart';
import 'band_fulfillment.dart';
import 'instrument_fulfillment.dart';
import 'place.dart';
import 'price.dart';

class Event {

  String id = "";
  String name;
  String description;
  AppProfile? owner;
  String imgUrl;
  String coverImgUrl;
  bool public;
  int createdTime;
  int eventDate;
  UsageReason reason;
  List<AppItem> appItems;
  List<String>? genres;
  double itemPercentageCoverage;
  int distanceKm;
  Price? paymentPrice;
  Price? coverPrice;
  EventType type;
  EventStatus status;
  Place? place;
  bool isFulfilled = false;
  List<InstrumentFulfillment> instrumentFulfillments;
  List<BandFulfillment> bandFulfillments;
  List<String>? watchingProfiles;
  List<String>? goingProfiles;
  bool isTest;

  Event({
      this.id = "",
      this.name = "",
      this.description = "",
      this.imgUrl = "",
      this.coverImgUrl = "",
      this.public = true,
      this.createdTime = 0,
      this.eventDate = 0,
      this.reason = UsageReason.any,
      this.appItems = const [],
      this.genres,
      this.itemPercentageCoverage = 0.0,
      this.distanceKm = 0,
      this.paymentPrice,
      this.coverPrice,
      this.type = EventType.rehearsal,
      this.status = EventStatus.draft,
      this.place,
      this.isFulfilled = false,
      this.instrumentFulfillments = const [],
      this.bandFulfillments = const [],
      this.isTest = false
  });


  @override
  String toString() {
    return 'Event{id: $id, name: $name, description: $description, owner: $owner, imgUrl: $imgUrl, coverImgUrl: $coverImgUrl, public: $public, createdTime: $createdTime, eventDate: $eventDate, reason: $reason, appItems: $appItems, genres: $genres, itemPercentageCoverage: $itemPercentageCoverage, distanceKm: $distanceKm, paymentPrice: $paymentPrice, coverPrice: $coverPrice, type: $type, status: $status, place: $place, isFulfilled: $isFulfilled, instrumentFulfillments: $instrumentFulfillments, bandFulfillments: $bandFulfillments, watchingProfiles: $watchingProfiles, goingProfiles: $goingProfiles, isTest: $isTest}';
  }

  Event.createBasic(this.name, desc):
    id = "",
    description = desc,
    imgUrl = "",
    coverImgUrl = "",
    public = true,
    appItems = [],
    genres = [],
    eventDate =  0,
    reason = UsageReason.any,
    itemPercentageCoverage = 0,
    distanceKm = 0,
    createdTime = 0,
    paymentPrice = Price(),
    coverPrice = Price(),
    type = EventType.rehearsal,
    status = EventStatus.draft,
    instrumentFulfillments = [],
    bandFulfillments = [],
    watchingProfiles = [],
    goingProfiles = [],
    isTest = false;

  Event.fromJSON(data):
      id = data["id"] ?? "",
      name = data["name"] ?? "",
      description = data["description"] ?? "",
      owner = AppProfile.fromJSON(data["owner"] ?? {}),
      imgUrl = data["imgUrl"] ?? "",
      coverImgUrl = data['coverImgUrl'] ?? "",
      public = data["public"] ?? true,
      createdTime = data["createdTime"] ?? 0,
      eventDate = data["eventDate"] ?? 0,
      reason = EnumToString.fromString(UsageReason.values, data["reason"] ?? UsageReason.any.name) ?? UsageReason.any,
      appItems = data["appItems"]?.map<AppItem>((item) {
        return AppItem.fromJSON(item);
      }).toList() ?? [],
      genres = List.from(data["genres"]?.cast<String>() ?? []),
      itemPercentageCoverage = data["itemPercentageCoverage"] ?? 0,
      distanceKm = data["distanceKm"] ?? 0,
      paymentPrice = Price.fromJSON(data["paymentPrice"] ?? {}),
      coverPrice = Price.fromJSON(data["coverPrice"] ?? {}),
      type = EnumToString.fromString(EventType.values, data["type"] ?? EventType.rehearsal.name) ?? EventType.rehearsal,
      status = EnumToString.fromString(EventStatus.values, data["status"] ?? EventStatus.draft.name) ?? EventStatus.draft,
      place =  Place.fromJSON(data["place"] ?? {}),
      isFulfilled = data["isFulfilled"] ?? false,
      instrumentFulfillments = data["instrumentFulfillments"]?.map<InstrumentFulfillment>((item) {
        return InstrumentFulfillment.fromJSON(item);
      }).toList()  ?? [],
      bandFulfillments = data["bandFulfillments"]?.map<BandFulfillment>((item) {
        return BandFulfillment.fromJSON(item);
      }).toList() ?? [],
      watchingProfiles = List.from(data["watchingProfiles"]?.cast<String>() ?? []),
      goingProfiles = List.from(data["goingProfiles"]?.cast<String>() ?? []),
      isTest = data["isTest"] ?? false;


  Map<String, dynamic> toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'owner': owner!.toJSON(),
    'imgUrl': imgUrl,
    'coverImgUrl': coverImgUrl,
    'public': public,
    'createdTime': createdTime,
    'eventDate': eventDate,
    'reason': reason.name,
    'appItem': appItems.map((appItem) => appItem.toJSON()).toList(),
    'genres': genres,
    'itemPercentageCoverage': itemPercentageCoverage,
    'distanceKm': distanceKm,
    'paymentPrice': paymentPrice?.toJSON() ?? Price().toJSON(),
    'coverPrice': coverPrice?.toJSON() ?? Price().toJSON(),
    'type': type.name,
    'status': status.name,
    'place': place?.toJSON() ?? Place().toJSON(),
    'isFulfilled': isFulfilled,
    'instrumentFulfillments': instrumentFulfillments.map((instrumentFulfillment) => instrumentFulfillment.toJSON()).toList(),
    'bandFulfillments': bandFulfillments.map((bandFulfillment) => bandFulfillment.toJSON()).toList(),
    'watchingProfiles': [],
    'goingProfiles': [],
    'isTest': isTest,
  };

}
