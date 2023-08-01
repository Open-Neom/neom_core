import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_flavour.dart';
import '../data/implementations/shared_preference_controller.dart';
import '../domain/model/activity_feed.dart';
import '../domain/model/app_item.dart';
import '../domain/model/app_profile.dart';
import '../domain/model/band.dart';
import '../domain/model/band_member.dart';
import '../domain/model/event.dart';
import '../domain/model/event_type_model.dart';
import '../domain/model/facility.dart';
import '../domain/model/genre.dart';
import '../domain/model/instrument.dart';
import '../domain/model/item_list.dart';
import '../domain/model/neom/chamber_preset.dart';
import '../domain/model/place.dart';
import '../domain/model/post.dart';
import 'app_utilities.dart';
import 'constants/app_assets.dart';
import 'constants/app_constants.dart';
import 'constants/message_translation_constants.dart';
import 'constants/url_constants.dart';
import 'enums/app_currency.dart';
import 'enums/app_item_state.dart';
import 'enums/event_type.dart';
import 'enums/post_type.dart';
import 'enums/profile_type.dart';
import 'enums/usage_reason.dart';

class CoreUtilities {

  // ignore: non_constant_identifier_names
  static Position JSONtoPosition(positionSnapshot){
    Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);
    try {
      if(positionSnapshot != null && positionSnapshot != "null") {
        dynamic positionJSON = jsonDecode(positionSnapshot);
        double longitude = positionJSON['longitude'];
        double latitude = positionJSON['latitude'];
        DateTime timestamp = DateTime.now();
        double accuracy = positionJSON['accuracy'];
        double altitude = positionJSON['altitude'];
        double heading = positionJSON['heading'];
        double speed = positionJSON['speed'];
        double speedAccuracy = positionJSON['speed_accuracy'];
        bool isMocked = positionJSON['is_mocked'];

        position = Position(longitude: longitude,
            latitude: latitude,
            timestamp: timestamp,
            accuracy: accuracy,
            altitude: altitude,
            heading: heading,
            speed: speed,
            speedAccuracy: speedAccuracy,
            isMocked: isMocked);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
  static List<AppItem> JSONtoItemlistItems(itemsIdsSnapshot){
    final itemIdString = jsonDecode(itemsIdsSnapshot.toString());
    List<AppItem> itemlistItems = [];
    try {
      if(!itemIdString["itemId"].isNullOrBlank) {
        List<dynamic> itemsJSON = jsonDecode(itemsIdsSnapshot);
        for (var itemJSON in itemsJSON) {
          itemlistItems.add(AppItem(
              id: itemJSON.id, state: itemJSON.itemState));
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return itemlistItems;
  }

  static AppItemState getItemState(int state){

    AppItemState appItem = AppItemState.noState;
    switch (state) {
      case 0:
        appItem = AppItemState.noState;
        break;
      case 1:
        appItem = AppItemState.heardIt;
        break;
      case 2:
        appItem = AppItemState.learningIt;
        break;
      case 3:
        appItem = AppItemState.needToPractice;
        break;
      case 4:
        appItem = AppItemState.readyToPlay;
        break;
      case 5:
        appItem = AppItemState.knowByHeart;
        break;
    }

    return appItem;
  }

  static Map<String, AppItem> getTotalItems(Map<String, Itemlist> itemlists){
    Map<String, AppItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appItem in itemlist.appItems!) {
        totalItems[appItem.id] = appItem;
      }
    });

    return totalItems;
  }

  static Map<String, ChamberPreset> getTotalPresets(Map<String, Itemlist> itemlists){
    Map<String, ChamberPreset> totalPresets = {};

    itemlists.forEach((key, itemlist) {
      for (var preset in itemlist.chamberPresets!) {
        totalPresets[preset.id] = preset;
      }
    });

    return totalPresets;
  }

  static Widget ratingImage(String asset) {
    return Image.asset(
      asset,
      height: 10.0,
      width: 10.0,
      color: Colors.blueGrey,
    );
  }

  static String getInstruments(Map<String,Instrument> profileInstruments) {
    AppUtilities.logger.d("start");
    String instruments = "";
    String mainInstrument = "";

    int instrumentsQty = profileInstruments.length;
    int index = 1;

    profileInstruments.forEach((key, value) {
      if (index < instrumentsQty) {
        if(value.isMain) {
          mainInstrument = key.tr;
        } else {
          instruments = "$instruments${key.tr} - ";
        }
      } else {
        instruments = instruments + key.tr;
      }
      index++;
    });

    if(instruments.length > AppConstants.maxInstrumentsNameLength) {
      instruments = "${instruments.substring(0,AppConstants.maxInstrumentsNameLength)}...";
    }

    return mainInstrument.isEmpty ? instruments : mainInstrument;
  }


  static List<AppItem> myFirstBook() {
    List<AppItem> myFirstAppItem = [];
    List<Genre> genres = [];
    genres.add(Genre(id: "Fiction", name: "Fiction"));

    myFirstAppItem.add(
        AppItem(
          id: "2drTDQAAQBAJ",
          state: AppItemState.heardIt.value,
          albumImgUrl: "http://books.google.com/books/content?id=2drTDQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api",
          artist: "Antoine de Saint-Exupéry" ,
          artistImgUrl: "http://books.google.com/books/content?id=2drTDQAAQBAJ&printsec=frontcover&img=1&zoom=5&edge=curl&source=gbs_api",
          previewUrl:"https://p.scdn.co/mp3-preview/50e82c99c20ffa4223e82250605bbd8500cb3928?cid=4e12110673b14aa5948c165a3531eea3",
          infoUrl: "https://play.google.com/store/books/details?id=2drTDQAAQBAJ&source=gbs_api",
          name: "El Principito",
          albumName: "SELECTOR",
          durationMs: 104,
          publishedDate: "2017-01-01",
          genres: genres
        )
    );

    return myFirstAppItem;
  }

  static List<AppItem> myFirstSong() {
    List<AppItem> myFirstAppItem = [];
    List<Genre> genres = [];
    genres.add(Genre(id: "Rock", name: "Rock"));

    myFirstAppItem.add(
        AppItem(
          id: "40riOy7x9W7GXjyGp4pjAv",
          state: AppItemState.heardIt.value,
          albumImgUrl: "https://i.scdn.co/image/ab67616d0000b2734637341b9f507521afa9a778",
          artist: "The Eagles" ,
          previewUrl:"https://p.scdn.co/mp3-preview/50e82c99c20ffa4223e82250605bbd8500cb3928?cid=4e12110673b14aa5948c165a3531eea3",
          name: "Hotel California - 2013 Remaster",
          albumName: "Hotel California (2013 Remaster)",
          durationMs: 391376,
          genres: genres
        )
    );

    return myFirstAppItem;
  }

  static String createCompositeInboxId(List<String> profileIds){
    StringBuffer compositeKeyBuffer = StringBuffer();
    for (var profileId in profileIds) {
      compositeKeyBuffer.write("${profileId}_");
    }
    AppUtilities.logger.d(compositeKeyBuffer.toString());
    return compositeKeyBuffer.toString();
  }

  //TODO
  // static void logEvent(String event, {Map<String, dynamic> parameter}) {
  //   kReleaseMode ? kAnalytics.logEvent(name: event, parameters: parameter)
  //       : print("[EVENT]: $event");
  // }

  static void launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      AppUtilities.logger.i('Could not launch $url');
    }
  }

  static void launchWhatsappURL(String phone, String message) async {
    String url = UrlConstants.whatsAppURL.replaceAll("<phoneNumber>", phone);
    url = url.replaceAll("<message>", message);

    if (await canLaunchUrl(Uri.parse("https://$url"))) { //TODO Verify how to use constant
      await launchUrl(Uri.parse(url));
    } else {
      AppUtilities.logger.i('Could not launch $url');
    }
  }

  static List<EventTypeModel> getEventTypes(){

    List<EventTypeModel> eventTypes = [];
    eventTypes.add(EventTypeModel(
        imgAssetPath: AppAssets.rehearsal,
        type: EventType.rehearsal)
    );
    eventTypes.add(EventTypeModel(
        imgAssetPath: AppAssets.microphone,
        type: EventType.gig)
    );
    eventTypes.add(EventTypeModel(
        imgAssetPath: AppAssets.festival,
        type: EventType.festival)
    );

    //TODO Add more event types as Class, Clinic, Event for musicians, etc

    return eventTypes;
  }


  static String getProfileMainFeature(AppProfile profile) {

    String profileMainFeature = "";

    switch(profile.type) {
      case(ProfileType.instrumentist):
        profileMainFeature = getMainInstrument(profile.instruments ?? <String, Instrument>{});
        break;
      case(ProfileType.facilitator):
        profileMainFeature = getMainFacility(profile.facilities ?? <String, Facility>{});
        break;
      case(ProfileType.host):
        profileMainFeature = getMainPlace(profile.places ?? <String, Place>{});
        break;
      case(ProfileType.researcher):
        profileMainFeature = CoreUtilities.getMainGenre(profile.genres ?? <String, Genre>{});
        break;
      case(ProfileType.fan):
        profileMainFeature = CoreUtilities.getMainGenre(profile.genres ?? <String, Genre>{});
        break;
      case(ProfileType.band):
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

  static String getAppItemHeroTag(int index) {
    return "APP_ITEM_HERO_TAG_$index";
  }

  static Future<List<Genre>> loadGenres() async {
    AppUtilities.logger.d("");
    List<Genre> genreList = [];

    try {
      String genreStr = await rootBundle.loadString(AppAssets.genresJsonPath);
      List<dynamic> genresJSON = jsonDecode(genreStr);

      for (var genreJSON in genresJSON) {
        genreList.add(Genre.fromJsonDefault(genreJSON));
      }

      AppUtilities.logger.d("${genreList.length} loaded instruments from json");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return genreList;
  }


  static Map<String, AppItem> getItemMatches(Map<String, AppItem> totalItems, List<String> profileItems){
    AppUtilities.logger.d("");
    Map<String, AppItem> matchedItemms = <String,AppItem>{};

    try {
      totalItems.forEach((itemId, item) {
        if(profileItems.contains(itemId)) {
          matchedItemms[itemId] = item;
          AppUtilities.logger.d("Adding $itemId - ItemmMatches Length ${matchedItemms.length}");
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return matchedItemms;
  }

  static Map<String, Instrument> getInstrumentMatches(Event event, Map<String,Instrument> profileInstruments) {
    Map<String, Instrument> matchedInstruments = <String, Instrument>{};

    try {
      for (var instrumentFulfillment in event.instrumentsFulfillment) {
        if(profileInstruments.containsKey(instrumentFulfillment.instrument.id)
            && !instrumentFulfillment.isFulfilled) {
          matchedInstruments[instrumentFulfillment.instrument.id] = instrumentFulfillment.instrument;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return matchedInstruments;
  }

  static List<Instrument> getBandInstrumentMatches(Band band, Map<String,Instrument> profileInstruments) {

    List<Instrument> bandInstrumentMatches = [];

    try {
      for (var bandMember in band.bandMembers!.values) {
        if(profileInstruments.containsKey(bandMember.instrument!.id)
            && bandMember.profileId.isEmpty) {
          bandInstrumentMatches.add(profileInstruments[bandMember.instrument!.id] ?? Instrument());
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
      AppUtilities.logger.e(e.toString());
    }

    return bandInstrumentMatches;
  }

  static bool fulfillmentMatchedRequirements({
    required Event event,
    required  Map<String, AppItem> requiredItems,
    required  Map<String, AppItem> matchedItems,
    required Map<String,Instrument> matchedInstruments,
    UsageReason profileReason = UsageReason.any,
    int profileDistanceKm = 0})
  {
    AppUtilities.logger.d("");

    bool requirementsMatched = false;

    try {

      if(matchedInstruments.isNotEmpty
          && event.distanceKm >= profileDistanceKm) {
        if(requiredItems.isNotEmpty && matchedItems.isNotEmpty || requiredItems.isEmpty) {
          requirementsMatched = true;
        }

      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    return requirementsMatched;
  }

  static Future<CachedNetworkImageProvider> handleCachedImageProvider(String imageUrl) async {

    CachedNetworkImageProvider cachedNetworkImageProvider = const CachedNetworkImageProvider("");

    try {
      if(imageUrl.isEmpty) {
        imageUrl = AppFlavour.getNoImageUrl();
      }

      Uri uri = Uri.parse(imageUrl);

      if(uri.host.isNotEmpty) {
        http.Response response = await http.get(uri);
        if (response.statusCode == 200) {
          cachedNetworkImageProvider = CachedNetworkImageProvider(imageUrl);
        } else {
          cachedNetworkImageProvider = CachedNetworkImageProvider(AppFlavour.getNoImageUrl());
        }
      }

    } catch (e){
      AppUtilities.logger.e(e.toString());
    }

    return cachedNetworkImageProvider;
  }

  Future<bool> isAvailableMediaUrl(String mediaUrl) async {
    AppUtilities.logger.i("Verifying if mediaUrl is available: $mediaUrl");

    bool isAvailable = true;
    try {
      Uri uri = Uri.parse(mediaUrl);
      http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        isAvailable = false;
      }
    } catch (e){
      AppUtilities.logger.e(e.toString());
      isAvailable = false;
    }
    return isAvailable;
  }


  Future<Post> verifyPostMediaUrls(Post post) async {
    if(post.profileImgUrl.isEmpty || !await isAvailableMediaUrl(post.profileImgUrl)) {
      post.profileImgUrl = AppFlavour.getNoImageUrl();
    }

    if(post.mediaUrl.isEmpty || !await isAvailableMediaUrl(post.mediaUrl)) {
      post.mediaUrl = AppFlavour.getNoImageUrl();
    }

    if(post.thumbnailUrl.isEmpty || !await isAvailableMediaUrl(post.thumbnailUrl)) {
      post.thumbnailUrl = AppFlavour.getNoImageUrl();
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


  Future<void> shareApp() async {
    ShareResult shareResult = await Share.shareWithResult('${MessageTranslationConstants.shareAppMsg.tr}\n'
        '${AppFlavour.getLinksUrl()}'
    );

    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }


  Future<void> shareAppWithPost(Post post) async {

    String thumbnailLocalPath = "";

    if(post.thumbnailUrl.isNotEmpty || post.mediaUrl.isNotEmpty ) {
      thumbnailLocalPath = await downloadImage(post);
    }

    ShareResult? shareResult;
    String caption = post.caption;
    if(post.type == PostType.blogEntry) {
      if(caption.contains(AppConstants.titleTextDivider)) {
        caption = caption.replaceAll(AppConstants.titleTextDivider, "\n\n");
      }
      String dotsLine = "";
      for(int i = 0; i < post.profileName.length; i++) {
        dotsLine = "$dotsLine.";
      }
      caption = "$caption\n\n${post.profileName}\n$dotsLine";
    }


    if(thumbnailLocalPath.isNotEmpty) {
      shareResult = await Share.shareXFiles([XFile(thumbnailLocalPath)],
          text: '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareAppMsg.tr}\n'
              '\n${AppFlavour.getLinksUrl()}\n'
      );
    } else {
      shareResult = await Share.shareWithResult(
          '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareAppMsg.tr}\n'
              '\n${AppFlavour.getLinksUrl()}\n'
      );
    }


    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedApp.tr,
          MessageTranslationConstants.sharedAppMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  Future<String> downloadImage(Post post) async {
    AppUtilities.logger.d("Entering downloadImage method");
    String imgLocalPath = "";
    try {

      final response = await http.get(Uri.parse(
          post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl
      ));

      if (response.statusCode == 200) {
        // Get the document directory path
        String localPath = await getLocalPath();
        imgLocalPath = "$localPath/${post.id}.jpeg";
        File jpegFileRef = File(imgLocalPath);
        await jpegFileRef.writeAsBytes(response.bodyBytes);
        AppUtilities.logger.i("Image downloaded to path $imgLocalPath successfully.");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return imgLocalPath;
  }

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  ///Deprecated
  String getYouTubeUrl(String content) {
    RegExp regExp = RegExp(
        r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?'
    );
    String matches = regExp.stringMatch(content) ?? "";

    final String youTubeUrl = matches;

    return youTubeUrl;
  }

  ///Deprecated
  List<ActivityFeed> getActivityFeedSinceLastCheck(List<ActivityFeed> activitiesFeed) {

    List<ActivityFeed> activityFeedSinceLastCheck = [];
    int lastNotificationCheckDate = Get.find<SharedPreferenceController>().lastNotificationCheckDate;
    DateTime lastNotificationCheckDateTime = DateTime.fromMillisecondsSinceEpoch(lastNotificationCheckDate);

    for (var activityFeed in activitiesFeed) {
      DateTime activityDate = DateTime.fromMillisecondsSinceEpoch(activityFeed.createdTime);
      if(activityDate.compareTo(lastNotificationCheckDateTime) > 0) {
        activityFeedSinceLastCheck.add(activityFeed);
      }
    }

    return activityFeedSinceLastCheck;
  }

}
