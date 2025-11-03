import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../utils/enums/release_type.dart';
import '../app_config.dart';
import '../app_properties.dart';
import '../domain/model/app_media_item.dart';
import '../domain/model/app_profile.dart';
import '../domain/model/app_release_item.dart';
import '../domain/model/band.dart';
import '../domain/model/band_member.dart';
import '../domain/model/event.dart';
import '../domain/model/external_item.dart';
import '../domain/model/facility.dart';
import '../domain/model/genre.dart';
import '../domain/model/instrument.dart';
import '../domain/model/item_list.dart';
import '../domain/model/neom/chamber.dart';
import '../domain/model/neom/chamber_preset.dart';
import '../domain/model/place.dart';
import '../domain/model/post.dart';
import 'constants/data_assets.dart';
import 'enums/app_currency.dart';
import 'enums/app_item_state.dart';
import 'enums/itemlist_type.dart';
import 'enums/media_item_type.dart';
import 'enums/profile_type.dart';
import 'enums/usage_reason.dart';
import 'position_utilities.dart';


class CoreUtilities {

  // ignore: non_constant_identifier_names
  static Position JSONtoPosition(positionSnapshot){
    Position position = Position(
        longitude: 0, latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0,
        heading: 0, speed: 0, speedAccuracy: 0,
        altitudeAccuracy: 1, headingAccuracy: 1
    );
    try {
      if(positionSnapshot != null && positionSnapshot != "null") {
        dynamic positionJSON = jsonDecode(positionSnapshot);
        double longitude = double.tryParse(positionJSON['longitude'].toString()) ?? 0;
        double latitude = double.tryParse(positionJSON['latitude'].toString()) ?? 0;
        DateTime timestamp = DateTime.now();
        double accuracy = double.tryParse(positionJSON['accuracy'].toString()) ?? 0;
        double altitude = double.tryParse(positionJSON['altitude'].toString()) ?? 0;
        double heading = double.tryParse(positionJSON['heading'].toString()) ?? 0;
        double speed = double.tryParse(positionJSON['speed'].toString()) ?? 0;
        double speedAccuracy = double.tryParse(positionJSON['speed_accuracy'].toString()) ?? 0;
        bool isMocked = positionJSON['is_mocked'];

        position = Position(longitude: longitude,
            latitude: latitude,
            timestamp: timestamp,
            accuracy: accuracy,
            altitude: altitude,
            heading: heading,
            speed: speed,
            speedAccuracy: speedAccuracy,
            isMocked: isMocked,
            altitudeAccuracy: 1,
            headingAccuracy: 1
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return position;
  }


  // ignore: non_constant_identifier_names
  static List<String> JSONtoItemIds(itemsIdsSnapshot){
    List<dynamic> itemsJSON = jsonDecode(itemsIdsSnapshot);
    List<String> itemIds = [];
    for (var itemJSON in itemsJSON) {
      itemIds.add(itemJSON);
    }

    return itemIds;
  }

  // ignore: non_constant_identifier_names
  static List<AppMediaItem> JSONtoItemlistItems(itemsIdsSnapshot){
    final itemIdString = jsonDecode(itemsIdsSnapshot.toString());
    List<AppMediaItem> itemlistItems = [];
    try {
      if(!itemIdString["itemId"].isNullOrBlank) {
        List<dynamic> itemsJSON = jsonDecode(itemsIdsSnapshot);
        for (var itemJSON in itemsJSON) {
          itemlistItems.add(AppMediaItem(
              id: itemJSON.id, state: itemJSON.itemState));
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return itemlistItems;
  }

  static AppItemState getItemState(int itemState){

    AppItemState state = AppItemState.noState;
    switch (itemState) {
      case 0:
        state = AppItemState.noState;
        break;
      case 1:
        state = AppItemState.heardIt;
        break;
      case 2:
        state = AppItemState.learningIt;
        break;
      case 3:
        state = AppItemState.needToPractice;
        break;
      case 4:
        state = AppItemState.readyToPlay;
        break;
      case 5:
        state = AppItemState.knowByHeart;
        break;
    }

    return state;
  }

  static Map<String, AppMediaItem> getTotalMediaItems(Map<String, Itemlist> itemlists){
    Map<String, AppMediaItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appMediaItem in itemlist.appMediaItems ?? []) {
        totalItems[appMediaItem.id] = appMediaItem;
      }
    });

    return totalItems;
  }

  static Map<String, AppReleaseItem> getTotalReleaseItems(Map<String, Itemlist> itemlists){
    Map<String, AppReleaseItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appReleaseItem in itemlist.appReleaseItems ?? []) {
        totalItems[appReleaseItem.id] = appReleaseItem;
      }
    });

    return totalItems;
  }

  static Map<String, ChamberPreset> getTotalPresets(Map<String, Chamber> chambers){
    Map<String, ChamberPreset> totalPresets = {};

    chambers.forEach((key, chamber) {
      for (var preset in chamber.chamberPresets ?? []) {
        totalPresets[preset.id] = preset;
      }
    });

    return totalPresets;
  }

  static Map<String, ExternalItem> getTotalExternalItems(Map<String, Itemlist> itemlists){
    Map<String, ExternalItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var externalItem in itemlist.externalItems ?? []) {
        totalItems[externalItem.id] = externalItem;
      }
    });

    return totalItems;
  }

  static int getTotalItemsQty(Map<String, Itemlist> itemlists){
    int totalItems = 0;

    itemlists.forEach((key, itemlist) {
      totalItems = totalItems + itemlist.getTotalItems();
    });

    return totalItems;
  }

  static String createCompositeInboxId(List<String> profileIds){
    StringBuffer compositeKeyBuffer = StringBuffer();
    for (var profileId in profileIds) {
      compositeKeyBuffer.write("${profileId}_");
    }
    AppConfig.logger.d(compositeKeyBuffer.toString());
    return compositeKeyBuffer.toString();
  }

  static String getProfileMainFeature(AppProfile profile) {

    String profileMainFeature = "";

    switch(profile.type) {
      case(ProfileType.appArtist):
        profileMainFeature = getMainInstrument(profile.instruments ?? <String, Instrument>{});
        break;
      case(ProfileType.facilitator):
        profileMainFeature = getMainFacility(profile.facilities ?? <String, Facility>{});
        break;
      case(ProfileType.host):
        profileMainFeature = getMainPlace(profile.places ?? <String, Place>{});
        break;
      default:
        profileMainFeature = CoreUtilities.getMainGenre(profile.genres ?? <String, Genre>{});
        break;
    }


    return profileMainFeature.isNotEmpty ? profileMainFeature : profile.type.value;
  }


  static String getMainInstrument(Map<String, Instrument> instruments){

    if(instruments.isEmpty) return "";

    Instrument mainInstrument = Instrument();
    for (var element in instruments.values) {
      if(element.isMain) mainInstrument = element;
    }

    return mainInstrument.name.isNotEmpty ? mainInstrument.name : instruments.values.first.name;
  }


  static String getMainGenre(Map<String, Genre> genres) {

    if(genres.isEmpty) return "";

    Genre mainGenre = Genre();
    for (var element in genres.values) {
      if(element.isMain) mainGenre = element;
    }

    return mainGenre.name.isNotEmpty ? mainGenre.name : genres.values.first.name;
  }

  static String getMainPlace(Map<String, Place> places){

    if(places.isEmpty) return "";

    Place mainPlace = Place();

    for (var element in places.values) {
      if(element.isMain) mainPlace = element;
    }

    return mainPlace.type.name;
  }


  static String getMainFacility(Map<String, Facility> facilities){

    if(facilities.isEmpty) return "";

    Facility mainFacility = Facility();
    for (var element in facilities.values) {
      if(element.isMain) mainFacility = element;
    }

    return mainFacility.type.name;
  }

  static Future<List<Genre>> loadGenres() async {
    AppConfig.logger.t("loadGenres");
    List<Genre> genreList = [];

    try {
      String genreStr = await rootBundle.loadString(DataAssets.genresJsonPath);
      List<dynamic> genresJSON = jsonDecode(genreStr);

      for (var genreJSON in genresJSON) {
        genreList.add(Genre.fromJsonDefault(genreJSON));
      }

      AppConfig.logger.d("${genreList.length} loaded genres from json");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return genreList;
  }


  static Map<String, AppItemState> getItemMatches(Map<String, AppMediaItem> totalItems, List<String> profileItems) {
    AppConfig.logger.t("Get Item Matches for ${totalItems.length} total items");
    Map<String, AppItemState> matchedItems = <String, AppItemState>{};

    try {
      totalItems.forEach((itemId, item) {
        if(profileItems.contains(itemId)) {
          matchedItems[itemId] = getItemState(item.state);
          AppConfig.logger.t("Adding Item Id: $itemId - Name: ${item.name}");
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    AppConfig.logger.d("Total ItemmMatches: ${matchedItems.length}");
    return matchedItems;
  }

  static Map<String, Instrument> getInstrumentMatches(Event event, Map<String,Instrument> profileInstruments) {
    Map<String, Instrument> matchedInstruments = <String, Instrument>{};

    try {
      for (var instrumentFulfillment in event.instrumentsFulfillment ?? []) {
        if(profileInstruments.containsKey(instrumentFulfillment.instrument.id)
            && !instrumentFulfillment.isFulfilled) {
          matchedInstruments[instrumentFulfillment.instrument.id] = instrumentFulfillment.instrument;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return matchedInstruments;
  }

  static List<Instrument> getBandInstrumentMatches(Band band, Map<String,Instrument> profileInstruments) {

    List<Instrument> bandInstrumentMatches = [];

    try {
      for (var bandMember in band.members!.values) {
        if(profileInstruments.containsKey(bandMember.instrument!.id)
            && bandMember.profileId.isEmpty) {
          bandInstrumentMatches.add(profileInstruments[bandMember.instrument!.id] ?? Instrument());
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return bandInstrumentMatches;
  }

  static Map<String, Instrument> getBandMemberInstrumentMatches(List<BandMember> bandMembers, Map<String,Instrument> profileInstruments) {

    Map<String, Instrument> bandInstrumentMatches = {};

    try {
      for (var bandMember in bandMembers) {
        if(profileInstruments.containsKey(bandMember.instrument!.id)
            && bandMember.profileId.isEmpty) {
          bandInstrumentMatches[profileInstruments[bandMember.instrument!.id]!.id] = profileInstruments[bandMember.instrument!.id] ?? Instrument();
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return bandInstrumentMatches;
  }

  static bool fulfillmentMatchedRequirements({
    required Event event,
    required  Map<String, AppMediaItem> requiredItems,
    required  Map<String, AppItemState> matchedItems,
    required Map<String,Instrument> matchedInstruments,
    UsageReason profileReason = UsageReason.any,
    int profileDistanceKm = 0})
  {
    AppConfig.logger.t("Fulfillment Matched Requirements");

    bool requirementsMatched = false;

    try {

      if(matchedInstruments.isNotEmpty && event.distanceKm >= profileDistanceKm) {
        if(requiredItems.isNotEmpty && matchedItems.isNotEmpty || requiredItems.isEmpty) {
          requirementsMatched = true;
        }

      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    return requirementsMatched;
  }

  Future<bool> isAvailableMediaUrl(String mediaUrl) async {
    AppConfig.logger.t("Verifying if mediaUrl is available: $mediaUrl");

    bool isAvailable = true;
    try {
      Uri uri = Uri.parse(mediaUrl);
      http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        isAvailable = false;
      }
    } catch (e){
      AppConfig.logger.e(e.toString());
      isAvailable = false;
    }
    return isAvailable;
  }


  Future<Post> verifyPostMediaUrls(Post post) async {
    if(post.profileImgUrl.isEmpty || !await isAvailableMediaUrl(post.profileImgUrl)) {
      post.profileImgUrl = AppProperties.getNoImageUrl();
    }

    if(post.mediaUrl.isEmpty || !await isAvailableMediaUrl(post.mediaUrl)) {
      post.mediaUrl = AppProperties.getNoImageUrl();
    }

    if(post.thumbnailUrl.isEmpty || !await isAvailableMediaUrl(post.thumbnailUrl)) {
      post.thumbnailUrl = AppProperties.getNoImageUrl();
    }

    return post;
  }


  static String getCurrencySymbol(AppCurrency currency) {
    String currencySymbol = "\u{0024}";
    switch(currency) {
      case (AppCurrency.mxn):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.appCoin):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.usd):
        currencySymbol = "\u{0024}";
        break;
      case (AppCurrency.eur):
        currencySymbol = "\u{20AC}";
        break;
      case (AppCurrency.gbp):
        currencySymbol = "\u{00A3}";
        break;
    }

    return currencySymbol;
  }

  static Map<double, AppProfile> sortProfilesByLocation(Position currentPosition, List<AppProfile> profiles) {
    SplayTreeMap<double, AppProfile> sortedProfiles = SplayTreeMap<double, AppProfile>();

    for (var mate in profiles) {
      double distanceBetweenProfiles = PositionUtilities.distanceBetweenPositions(
          currentPosition, mate.position!);
      distanceBetweenProfiles = distanceBetweenProfiles + Random().nextDouble();
      sortedProfiles[distanceBetweenProfiles] = mate;
    }

    AppConfig.logger.d("Sorted Profiles ${sortedProfiles.length}");
    return Map.from(sortedProfiles);
  }

  static Map<String, AppProfile> sortProfilesByName(List<AppProfile> profiles) {

    profiles.sort((a, b) => a.name.compareTo(b.name));

    Map<String, AppProfile> profileMap = LinkedHashMap.fromIterable(
      profiles,
      key: (profile) => profile.name,
      value: (profile) => profile,
    );

    return profileMap;
  }

  static List<Itemlist> filterItemlists(List<Itemlist> lists, ItemlistType type) {
    if(lists.isEmpty) return [];

    switch(type) {
      case ItemlistType.playlist:
        lists.removeWhere((list) => list.type == ItemlistType.readlist);
        lists.removeWhere((list) => list.type == ItemlistType.giglist);
        break;
      case ItemlistType.readlist:
        lists.removeWhere((list) => list.type != ItemlistType.readlist);
      default:
        break;
    }

    return lists;
  }

  static bool isInternal(String url) {
    final bool isInternal = url.contains(AppProperties.getHubName())
        || url.contains(AppProperties.getStorageServerName());
    return isInternal;
  }

  static bool isWithinFirstMonth(int createdTime) {
    DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(createdTime);
    DateTime now = DateTime.now();

    DateTime dateOneMonthLater = DateTime(
      creationDate.year,
      creationDate.month + 1,
      creationDate.day,
    );

    return now.isBefore(dateOneMonthLater);
  }

  static void exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  static MediaItemType getMediaItemType(AppReleaseItem releaseItem) {

    MediaItemType itemType = MediaItemType.song;

    switch (releaseItem.type) {
      case ReleaseType.single:
        if (releaseItem.previewUrl.toLowerCase().endsWith('.pdf')) {
          itemType =  MediaItemType.pdf;
        }
        break;
      case ReleaseType.episode:
        itemType = MediaItemType.podcast;
      case ReleaseType.chapter:
        itemType = MediaItemType.audiobook;
      default:
        itemType = MediaItemType.song;
    }

    return itemType;
  }

}
