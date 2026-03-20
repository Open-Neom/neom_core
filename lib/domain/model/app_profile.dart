import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_config.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../../utils/enums/verification_level.dart';
import 'facility.dart';
import 'genre.dart';
import 'influence.dart';
import 'instrument.dart';
import 'item_list.dart';
import 'neom/neom_chamber.dart';
import 'neom/neom_frequency.dart';
import 'place.dart';
import 'review.dart';

class AppProfile {

  String id;
  String name;
  String aboutMe;
  String photoUrl;
  String coverImgUrl;
  String mainFeature;
  int lastTimeOn = 0;

  bool isActive;
  Position? position;
  String address;
  String phoneNumber;
  ProfileType type;
  UsageReason usageReason;

  double reviewStars =  10.0;
  Review? lastReview;

  List<String>? itemmates;
  List<String>? eventmates;
  List<String>? followers;
  List<String>? following;
  List<String>? unfollowing;
  List<String>? blockTo;
  List<String>? blockedBy;

  List<String>? posts;
  List<String>? blogEntries;

  List<String>? comments;
  List<String>? hiddenPosts;
  List<String>? hiddenComments;
  List<String>? bannedGenres;
  List<String>? reports;

  List<String>? bands;
  List<String>? events;
  List<String>? reviews;

  List<String>? favoriteItems; ///EACH LIKED APPMEDIAITEM OR APPRELEASEITEM ID GOES HERE TO FETCH FROM GLOBAL DB
  List<String>? savedItemlistIds; /// IDs of other users' playlists saved to library
  List<String>? chamberPresets; ///NEOM USAGE
  List<String>? watchingEvents; ///EVENT THE USER IS FOLLOWING TO VERIFY IF GOING OR TO GET FEED
  List<String>? goingEvents; //////EVENT WHERE USER IS GOING
  List<String>? playingEvents; ///EVENT WHERE USER IS PARTICIPATING

  List<String>? requests;
  List<String>? sentRequests;
  List<String>? invitationRequests;

  ///These are retrieved from a Firebase Collection
  Map<String, Itemlist>? itemlists;
  Map<String, Itemlist>? giglists;
  Map<String, Instrument>? instruments;
  Map<String, NeomChamber>? chambers;
  Map<String, NeomFrequency>? frequencies;
  Map<String, Genre>? genres;
  Map<String, Facility>? facilities;
  Map<String, Place>? places;

  List<String>? badges;
  List<Influence>? influences;
  int totalTipsReceived;

  bool directoryVisible;
  bool showPhone;
  VerificationLevel verificationLevel;
  int lastNameUpdate = 0;
  String slug;

  AppProfile({
    this.id = "",
    this.name = "",
    this.position,
    this.address = "",
    this.phoneNumber = "",
    this.photoUrl = "",
    this.coverImgUrl = "",
    this.aboutMe = "",
    this.usageReason = UsageReason.casual,
    this.mainFeature = "",
    this.reviewStars = 10.0,
    this.isActive = false,
    this.type = ProfileType.general,
    this.directoryVisible = true,
    this.showPhone = true,
    this.totalTipsReceived = 0,
    this.verificationLevel = VerificationLevel.none,
    this.lastNameUpdate = 0,
    this.slug = "",
    this.itemmates,
    this.eventmates,
    this.followers,
    this.following,
    this.unfollowing,
    this.blockTo,
    this.blockedBy,
    this.posts,
    this.blogEntries,
    this.comments,
    this.hiddenPosts,
    this.hiddenComments,
    this.reports,
    this.bands,
    this.events,
    this.reviews,
    this.favoriteItems,
    this.savedItemlistIds,
    this.chamberPresets,
    this.watchingEvents,
    this.goingEvents,
    this.playingEvents,
    this.requests,
    this.sentRequests,
    this.invitationRequests,
    this.itemlists,
    this.giglists,
    this.instruments,
    this.chambers,
    this.frequencies,
    this.genres,
    this.facilities,
    this.places,
    this.badges,
    this.influences,
    this.lastReview,
    this.bannedGenres,
  });

  /// Generates a URL slug from a profile name.
  /// "Serzen Montoya" → "serzenmontoya"
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñü]'), '');
  }

  @override
  String toString() {
    return 'AppProfile{id: $id, name: $name, aboutMe: $aboutMe, photoUrl: $photoUrl, coverImgUrl: $coverImgUrl, mainFeature: $mainFeature, lastTimeOn: $lastTimeOn, isActive: $isActive, position: $position, address: $address, phoneNumber: $phoneNumber, type: $type, usageReason: $usageReason, reviewStars: $reviewStars, lastReview: $lastReview, itemmates: $itemmates, eventmates: $eventmates, followers: $followers, following: $following, unfollowing: $unfollowing, blockTo: $blockTo, blockedBy: $blockedBy, posts: $posts, blogEntries: $blogEntries, comments: $comments, hiddenPosts: $hiddenPosts, hiddenComments: $hiddenComments, bannedGenres: $bannedGenres, reports: $reports, bands: $bands, events: $events, reviews: $reviews, favoriteItems: $favoriteItems, chamberPresets: $chamberPresets, watchingEvents: $watchingEvents, goingEvents: $goingEvents, playingEvents: $playingEvents, requests: $requests, sentRequests: $sentRequests, invitationRequests: $invitationRequests, itemlists: $itemlists, instruments: $instruments, chambers: $chambers, frequencies: $frequencies, genres: $genres, facilities: $facilities, places: $places, directoryVisible: $directoryVisible, showPhone: $showPhone,'
        ' verificationLevel: $verificationLevel, lastNameUpdate: $lastNameUpdate,'
        ' slug: $slug, badges: $badges, influences: $influences, totalTipsReceived: $totalTipsReceived, giglists: $giglists}';
  }

  Map<String, dynamic> toJSON() {
    AppConfig.logger.t("Profile toJSON");
    return <String, dynamic> {
      'id': id,
      'name': name,
      'position': jsonEncode(position),
      'address': address,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'coverImgUrl': coverImgUrl,
      'aboutMe': aboutMe,
      'mainFeature': mainFeature,
      'reviewStars': reviewStars,
      'isActive': isActive,
      'type': type.name,
      'usageReason': usageReason.name,
      'lastReview': lastReview?.toJSON() ?? Review().toJSON(),
      'bannedGenres': bannedGenres,
      'itemmates': itemmates,
      'eventmates': eventmates,
      'following': following,
      'followers': followers,
      'unfollowing': unfollowing,
      'blockTo': blockTo,
      'blockedBy': blockedBy,
      'posts': posts,
      'blogEntries': blogEntries,
      'comments': comments,
      'hiddenPosts': hiddenPosts,
      'hiddenComments': hiddenComments,
      'reports': reports,
      'bands': bands,
      'events': events,
      'reviews': reviews,
      'favoriteItems': favoriteItems,
      'savedItemlistIds': savedItemlistIds,
      'chamberPresets': chamberPresets,
      'watchingEvents': watchingEvents,
      'goingEvents': goingEvents,
      'playingEvents': playingEvents,
      'requests': requests,
      'sentRequests': sentRequests,
      'invitationRequests': invitationRequests,
      'badges': badges,
      'influences': influences?.map((i) => i.toJSON()).toList() ?? [],
      'totalTipsReceived': totalTipsReceived,
      'directoryVisible': directoryVisible,
      'showPhone': showPhone,
      'verificationLevel': verificationLevel.name,
      'lastNameUpdate': lastNameUpdate,
      'slug': slug,
      'itemlists': itemlists?.map((key, value) => MapEntry(key, value.toJSON())),
      'giglists': giglists?.map((key, value) => MapEntry(key, value.toJSON())),
      'instruments': instruments?.map((key, value) => MapEntry(key, value.toJSON())),
      'chambers': chambers?.map((key, value) => MapEntry(key, value.toJSON())),
      'frequencies': frequencies?.map((key, value) => MapEntry(key, value.toJSON())),
      'genres': genres?.map((key, value) => MapEntry(key, value.toJSON())),
      'facilities': facilities?.map((key, value) => MapEntry(key, value.toJSON())),
      'places': places?.map((key, value) => MapEntry(key, value.toJSON())),


    };
  }

  Map<String, dynamic> toJSONWithFacilities() {
    AppConfig.logger.t("Profile toJSON");
    return <String, dynamic> {
      'id': id,
      'name': name,
      'position': jsonEncode(position),
      'address': address,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'coverImgUrl': coverImgUrl,
      'aboutMe': aboutMe,
      'mainFeature': mainFeature,
      'reviewStars': reviewStars,
      'isActive': isActive,
      'type': type.name,
      'usageReason': usageReason.name,
      'lastReview': lastReview?.toJSON() ?? Review().toJSON(),
      'bannedGenres': bannedGenres,
      'itemmates': itemmates,
      'eventmates': eventmates,
      'following': following,
      'followers': followers,
      'unfollowing': unfollowing,
      'blockTo': blockTo,
      'blockedBy': blockedBy,
      'posts': posts,
      'blogEntries': blogEntries,
      'comments': comments,
      'hiddenPosts': hiddenPosts,
      'hiddenComments': hiddenComments,
      'reports': reports,
      'bands': bands,
      'events': events,
      'reviews': reviews,
      'favoriteItems': favoriteItems,
      'savedItemlistIds': savedItemlistIds,
      'chamberPresets': chamberPresets,
      'watchingEvents': watchingEvents,
      'goingEvents': goingEvents,
      'playingEvents': playingEvents,
      'requests': requests,
      'sentRequests': sentRequests,
      'invitationRequests': invitationRequests,
      'badges': badges,
      'influences': influences?.map((i) => i.toJSON()).toList() ?? [],
      'totalTipsReceived': totalTipsReceived,
      'directoryVisible': directoryVisible,
      'showPhone': showPhone,
      'verificationLevel': verificationLevel.name,
      'lastNameUpdate': lastNameUpdate,
      'slug': slug,
      'itemlists': itemlists?.map((key, value) => MapEntry(key, value.toJSON())),
      'giglists': giglists?.map((key, value) => MapEntry(key, value.toJSON())),
      'facilities': facilities != null
          ? facilities!.map((key, facility) => MapEntry(key, facility.toJSON()))
          : {},
    };
  }

  AppProfile.fromJSON(dynamic data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        photoUrl = data["photoUrl"] ?? "",
        coverImgUrl = data["coverImgUrl"] ?? "",
        type = EnumToString.fromString(ProfileType.values, data["type"] ?? ProfileType.general.value) ?? ProfileType.general,
        usageReason = EnumToString.fromString(UsageReason.values, data["usageReason"] ?? UsageReason.casual.name) ?? UsageReason.casual,
        aboutMe = data["aboutMe"] ?? "",
        reviewStars = double.tryParse(data["reviewStars"].toString()) ?? 10,
        mainFeature = data["mainFeature"] ?? "",
        isActive = data["isActive"] ?? true,
        position = CoreUtilities.JSONtoPosition(data["position"]),
        address = data["address"] ?? '',
        phoneNumber = data["phoneNumber"] ?? '',
        bannedGenres = data["bannedGenres"]?.cast<String>() ?? [],
        itemmates = data["itemmates"]?.cast<String>() ?? [],
        eventmates = data["eventmates"]?.cast<String>() ?? [],
        following = data["following"]?.cast<String>() ?? [],
        followers = data["followers"]?.cast<String>() ?? [],
        unfollowing = data["unfollowing"]?.cast<String>() ?? [],
        blockTo = data["blockTo"]?.cast<String>() ?? [],
        blockedBy = data["blockedBy"]?.cast<String>() ?? [],
        posts = data["posts"]?.cast<String>() ?? [],
        blogEntries = data["blogEntries"]?.cast<String>() ?? [],
        comments = data["comments"]?.cast<String>() ?? [],
        hiddenPosts = data["hiddenPosts"]?.cast<String>() ?? [],
        hiddenComments = data["hiddenComments"]?.cast<String>() ?? [],
        reports = data["reports"]?.cast<String>() ?? [],
        bands = data["bands"]?.cast<String>() ?? [],
        events = data["events"]?.cast<String>() ?? [],
        reviews = data["reviews"]?.cast<String>() ?? [],
        favoriteItems = data["favoriteItems"]?.cast<String>() ?? [],
        savedItemlistIds = data["savedItemlistIds"]?.cast<String>() ?? [],
        chamberPresets = data["chamberPresets"]?.cast<String>() ?? [],
        watchingEvents = data["watchingEvents"]?.cast<String>() ?? [],
        goingEvents = data["goingEvents"]?.cast<String>() ?? [],
        playingEvents = data["playingEvents"]?.cast<String>() ?? [],
        requests = data["requests"]?.cast<String>() ?? [],
        sentRequests = data["sentRequests"]?.cast<String>() ?? [],
        invitationRequests = data["invitationRequests"]?.cast<String>() ?? [],
        badges = data["badges"]?.cast<String>() ?? [],
        influences = (data["influences"] as List?)?.map((i) => Influence.fromJSON(i)).toList() ?? [],
        totalTipsReceived = data["totalTipsReceived"] ?? 0,
        directoryVisible = data["directoryVisible"] ?? true,
        showPhone = data["showPhone"] ?? true,
        verificationLevel = EnumToString.fromString(VerificationLevel.values, data["verificationLevel"] ?? VerificationLevel.none.name) ?? VerificationLevel.none,
        lastNameUpdate = data["lastNameUpdate"] ?? 0,
        slug = data["slug"] ?? "",
        giglists = data["giglists"] != null
            ? (data["giglists"] as Map).map((key, value) {
          return MapEntry(
              key.toString(),
              Itemlist.fromJSON(Map<String, dynamic>.from(value))
          );
        }) : {},
        facilities = data["facilities"] != null
            ? (data["facilities"] as Map).map((key, value) {
          return MapEntry(
              key.toString(),
              Facility.fromJSON(Map<String, dynamic>.from(value))
          );
        }) : {};

  AppProfile.fromProfileInstruments(dynamic data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        photoUrl = data["photoUrl"] ?? "",
        usageReason = EnumToString.fromString(UsageReason.values, data["usageReason"] ?? UsageReason.casual.name) ?? UsageReason.casual,
        aboutMe = data["aboutMe"] ?? "",
        mainFeature = data["mainFeature"] ?? "",
        position = data["position"] is Map<dynamic,dynamic> ? Position.fromMap(data["position"]) : null,
        address = data["address"] ?? '',
        phoneNumber = data["phoneNumber"] ?? '',
        favoriteItems = data["favoriteItems"]?.cast<String>() ?? [],
        savedItemlistIds = data["savedItemlistIds"]?.cast<String>() ?? [],
        chamberPresets = data["chamberPresets"]?.cast<String>() ?? [],
        instruments = { for (var e in data["instruments"]?.cast<String>() ?? []) e : Instrument() },
        frequencies = { for (var e in data["frequencies"]?.cast<String>() ?? []) e : NeomFrequency() },
        type = ProfileType.appArtist,
        coverImgUrl = "",
        isActive = true,
        badges = [],
        totalTipsReceived = 0,
        directoryVisible = true,
        showPhone = true,
        verificationLevel = EnumToString.fromString(VerificationLevel.values, data["verificationLevel"] ?? VerificationLevel.none.name) ?? VerificationLevel.none,
        slug = data["slug"] ?? "";


  Map<String, dynamic> toProfileInstrumentsJSON() {
    AppConfig.logger.d("Profile toJSON for Firestore with no Id");
    return <String, dynamic>{
      'id': id,
      'name': name,
      'position': position?.toJson(),
      'photoUrl': photoUrl,
      'aboutMe': aboutMe,
      'usageReason': usageReason.name,
      'chamberPresets': chamberPresets,
      'genres': genres?.values.map((genre) => genre.name).toList(),
      'mainFeature': mainFeature,
      'instruments': instruments?.values.map((instrument) => instrument.name).toList(),
      'frequencies': frequencies?.values.map((frequency) => frequency.name).toList(),
      'influences': influences?.map((i) => i.toJSON()).toList() ?? [],
      'verificationLevel': verificationLevel.name
    };
  }

}
