import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_music_player/ui/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../neom_commons.dart';
import '../domain/model/app_media_item.dart';
import '../domain/model/app_release_item.dart';
import '../domain/model/neom/chamber_preset.dart';
import 'enums/media_item_type.dart';

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
            isMocked: isMocked,
            altitudeAccuracy: 1,
            headingAccuracy: 1
        );
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
      AppUtilities.logger.e(e.toString());
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
      for (var appMediaItem in itemlist.appMediaItems!) {
        totalItems[appMediaItem.id] = appMediaItem;
      }
    });

    return totalItems;
  }

  static Map<String, AppReleaseItem> getTotalReleaseItems(Map<String, Itemlist> itemlists){
    Map<String, AppReleaseItem> totalItems = {};

    itemlists.forEach((key, itemlist) {
      for (var appReleaseItem in itemlist.appReleaseItems!) {
        totalItems[appReleaseItem.id] = appReleaseItem;
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
    AppUtilities.logger.t("getInstruments on String value");
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


  static List<AppMediaItem> myFirstBook() {
    List<AppMediaItem> myFirstAppItem = [];
    List<Genre> genres = [];
    genres.add(Genre(id: "Fiction", name: "Fiction"));

    myFirstAppItem.add(
        AppMediaItem(
          id: "2drTDQAAQBAJ",
          state: AppItemState.heardIt.value,
          artist: "Antoine de Saint-Exupéry" ,
          imgUrl: "http://books.google.com/books/content?id=2drTDQAAQBAJ&printsec=frontcover&img=1&zoom=5&edge=curl&source=gbs_api",
          url:"https://play.google.com/store/books/details?id=2drTDQAAQBAJ&source=gbs_api",
          permaUrl: "https://play.google.com/store/books/details?id=2drTDQAAQBAJ&source=gbs_api",
          name: "El Principito",
          album: "SELECTOR",
          duration: 104,
          publishedYear: 2017,
          genres: genres.map((e) => e.name).toList()
        )
    );

    return myFirstAppItem;
  }

  static List<AppMediaItem> myFirstSong() {
    List<AppMediaItem> myFirstAppItem = [];
    List<Genre> genres = [];
    genres.add(Genre(id: "Rock", name: "Rock"));

    myFirstAppItem.add(
        AppMediaItem(
          id: "40riOy7x9W7GXjyGp4pjAv",
          state: AppItemState.heardIt.value,
          imgUrl: "https://i.scdn.co/image/ab67616d0000b2734637341b9f507521afa9a778",
          artist: "The Eagles" ,
          url:"https://p.scdn.co/mp3-preview/50e82c99c20ffa4223e82250605bbd8500cb3928?cid=4e12110673b14aa5948c165a3531eea3",
          name: "Hotel California - 2013 Remaster",
          album: "Hotel California (2013 Remaster)",
          duration: 391,
          genres: genres.map((e) => e.name).toList(),
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

  static void launchURL(String url, {bool openInApp = true}) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url),
            mode: openInApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication
        );
      } else {
        AppUtilities.logger.i('Could not launch $url');
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static void launchWhatsappURL(String phone, String message) async {
    try {
      String url = UrlConstants.whatsAppURL.replaceAll("<phoneNumber>", phone);
      url = url.replaceAll("<message>", message);

      if (await canLaunchUrl(Uri.parse("https://$url"))) { //TODO Verify how to use constant
        await launchUrl(Uri.parse(url));
      } else {
        AppUtilities.logger.i('Could not launch $url');
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static void launchGoogleMaps({String? address, Place? place}) async {
    try {
      String mapsQuery = '';
      if(address != null) {
        mapsQuery = address;
      } else if(place != null) {
        StringBuffer placeAddress = StringBuffer();
        placeAddress.write(place.name);
        placeAddress.write(',');
        placeAddress.write(place.address!.street);
        placeAddress.write(',');
        placeAddress.write(place.address!.city);
        placeAddress.write(',');
        placeAddress.write(place.address!.state);
        placeAddress.write(',');
        placeAddress.write(place.address!.country);
        AppUtilities.logger.i(placeAddress.toString());
        mapsQuery = placeAddress.toString();
      }

      String mapOptions = Uri.encodeComponent(mapsQuery);
      final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$mapOptions";
      launchURL(googleMapsUrl);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
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
    AppUtilities.logger.t("loadGenres");
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


  static Map<String, AppMediaItem> getItemMatches(Map<String, AppMediaItem> totalItems, List<String> profileItems) {
    AppUtilities.logger.t("Get Item Matches for ${totalItems.length} total items");
    Map<String, AppMediaItem> matchedItemms = <String,AppMediaItem>{};

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
      for (var bandMember in band.members!.values) {
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
    required  Map<String, AppMediaItem> requiredItems,
    required  Map<String, AppMediaItem> matchedItems,
    required Map<String,Instrument> matchedInstruments,
    UsageReason profileReason = UsageReason.any,
    int profileDistanceKm = 0})
  {
    AppUtilities.logger.d("fulfillmentMatchedRequirements");

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
    AppUtilities.logger.t("Verifying if mediaUrl is available: $mediaUrl");

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
      String imgUrl = post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl;
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await downloadImage(imgUrl);
      }
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

  Future<void> shareAppWithMediaItem(AppMediaItem mediaItem) async {

    String thumbnailLocalPath = "";

    if(mediaItem.imgUrl.isNotEmpty || (mediaItem.allImgs?.isNotEmpty ?? false) ) {
      String imgUrl = mediaItem.imgUrl.isNotEmpty ? mediaItem.imgUrl : mediaItem.allImgs?.first ?? "";
      if(imgUrl.isNotEmpty) {
        thumbnailLocalPath = await downloadImage(imgUrl, imgName: "${mediaItem.artist}_${mediaItem.name}");
      }
    }

    ShareResult? shareResult;
    String caption = mediaItem.name;
    if(mediaItem.type == MediaItemType.song) {
      if(caption.contains(AppConstants.titleTextDivider)) {
        caption = caption.replaceAll(AppConstants.titleTextDivider, "\n\n");
      }
      String dotsLine = "";
      for(int i = 0; i < mediaItem.artist.length; i++) {
        dotsLine = "$dotsLine.";
      }
      caption = "$caption\n\n${mediaItem.artist}\n$dotsLine";
    }


    if(thumbnailLocalPath.isNotEmpty) {
      shareResult = await Share.shareXFiles([XFile(thumbnailLocalPath)],
          text: '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareMediaItem.tr}\n'
              '\n${AppFlavour.getLinksUrl()}\n'
      );
    } else {
      shareResult = await Share.shareWithResult(
          '$caption${caption.isNotEmpty ? "\n\n" : ""}'
              '${MessageTranslationConstants.shareMediaItemMsg.tr}\n'
              '\n${AppFlavour.getLinksUrl()}\n'
      );
    }


    if(shareResult.status == ShareResultStatus.success && shareResult.raw != "null") {
      Get.snackbar(MessageTranslationConstants.sharedMediaItem.tr,
          MessageTranslationConstants.sharedMediaItemMsg.tr,
          snackPosition: SnackPosition.bottom);
    }

  }

  static Future<String> downloadImage(String imgUrl, {String imgName = ''}) async {
    AppUtilities.logger.d("Entering downloadImage method");
    String localPath = "";
    String name = imgName.isNotEmpty ? imgName : imgUrl;
    try {

      final response = await http.get(Uri.parse(imgUrl));
      if (response.statusCode == 200) {
        name = name.replaceAll(".", "").replaceAll(":", "").replaceAll("/", "");
        // Get the document directory path
        localPath = await getLocalPath();
        localPath = "$localPath/$name.jpeg";
        File jpegFileRef = File(localPath);
        await jpegFileRef.writeAsBytes(response.bodyBytes);
        AppUtilities.logger.i("Image downloaded to path $localPath successfully.");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return localPath;
  }

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  ///Deprecated
  // String getYouTubeUrl(String content) {
  //   RegExp regExp = RegExp(
  //       r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?'
  //   );
  //   String matches = regExp.stringMatch(content) ?? "";
  //
  //   final String youTubeUrl = matches;
  //
  //   return youTubeUrl;
  // }

  ///Deprecated
  // List<ActivityFeed> getActivityFeedSinceLastCheck(List<ActivityFeed> activitiesFeed) {
  //
  //   List<ActivityFeed> activityFeedSinceLastCheck = [];
  //   int lastNotificationCheckDate = Get.find<SharedPreferenceController>().lastNotificationCheckDate;
  //   DateTime lastNotificationCheckDateTime = DateTime.fromMillisecondsSinceEpoch(lastNotificationCheckDate);
  //
  //   for (var activityFeed in activitiesFeed) {
  //     DateTime activityDate = DateTime.fromMillisecondsSinceEpoch(activityFeed.createdTime);
  //     if(activityDate.compareTo(lastNotificationCheckDateTime) > 0) {
  //       activityFeedSinceLastCheck.add(activityFeed);
  //     }
  //   }
  //
  //   return activityFeedSinceLastCheck;
  // }

  static String removeQueryParameters(String url) {
    final int questionMarkIndex = url.indexOf('?');
    if (questionMarkIndex == -1) {
      return url;
    }

    return url.substring(0, questionMarkIndex);
  }

  static void copyToClipboard({
    required BuildContext context,
    required String text,
    String? displayText,
  }) {
    Clipboard.setData(
      ClipboardData(text: text),
    );
    ShowSnackBar().showSnackBar(
      context,
      displayText ?? AppTranslationConstants.copied.tr,
    );
  }

}
