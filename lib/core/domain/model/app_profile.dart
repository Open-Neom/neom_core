import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../utils/app_utilities.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';
import 'facility.dart';
import 'genre.dart';
import 'instrument.dart';
import 'item_list.dart';
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
  int lastSpotifySync = 0;
  double reviewStars =  10.0;
  bool isActive;
  Position? position;
  String address;
  ProfileType type;
  UsageReason reason;

  Review? lastReview;

  List<String>? bannedGenres;
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
  List<String>? reports;
  List<String>? bands;
  List<String>? events;
  List<String>? reviews;

  List<String>? favoriteItems; ///EACH LIKED APPMEDIAITEM ID GOES HERE TO FETCH FROM GLOBAL DB
  // List<String>? appMediaItems; //TODOVERIFY IF NEEDED TO ANOTHER TYPE OF SORT
  List<String>? chamberPresets;
  List<String>? watchingEvents;
  List<String>? goingEvents;
  List<String>? playingEvents;

  List<String>? requests;
  List<String>? sentRequests;
  List<String>? invitationRequests;

  ///These are retrieved from a Firebase Collection
  Map<String, Itemlist>? itemlists;
  Map<String, Instrument>? instruments;
  Map<String, NeomFrequency>? frequencies;
  Map<String, Genre>? genres;
  Map<String, Facility>? facilities;
  Map<String, Place>? places;

  bool showInDirectory;
  bool isVerified;
  int lastNameUpdate = 0;

  AppProfile({
    this.id = "",
    this.name = "",
    this.position,
    this.address = "",
    this.photoUrl = "",
    this.coverImgUrl = "",
    this.aboutMe = "",
    this.reason = UsageReason.any,
    this.mainFeature = "",
    this.lastSpotifySync = 0,
    this.reviewStars = 10.0,
    this.isActive = false,
    this.type = ProfileType.instrumentist,
    this.showInDirectory = false,
    this.isVerified = false,
    this.lastNameUpdate = 0,
  });


  @override
  String toString() {
    return 'AppProfile{id: $id, name: $name, aboutMe: $aboutMe, photoUrl: $photoUrl, coverImgUrl: $coverImgUrl, mainFeature: $mainFeature, lastTimeOn: $lastTimeOn, lastSpotifySync: $lastSpotifySync, reviewStars: $reviewStars, isActive: $isActive, position: $position, address: $address, type: $type, reason: $reason, lastReview: $lastReview, bannedGenres: $bannedGenres, itemmates: $itemmates, eventmates: $eventmates, followers: $followers, following: $following, unfollowing: $unfollowing, blockTo: $blockTo, blockedBy: $blockedBy, posts: $posts, blogEntries: $blogEntries, comments: $comments, hiddenPosts: $hiddenPosts, hiddenComments: $hiddenComments, reports: $reports, bands: $bands, events: $events, reviews: $reviews, appItems: $favoriteItems, chamberPresets: $chamberPresets, watchingEvents: $watchingEvents, goingEvents: $goingEvents, playingEvents: $playingEvents, requests: $requests, sentRequests: $sentRequests, invitationRequests: $invitationRequests, itemlists: $itemlists, instruments: $instruments, frequencies: $frequencies, genres: $genres, facilities: $facilities, places: $places, showInDirectory: $showInDirectory}';
  }

  Map<String, dynamic> toJSON() {
    AppUtilities.logger.t("Profile toJSON");
    return <String, dynamic> {
      'id': id,
      'name': name,
      'position': jsonEncode(position),
      'photoUrl': photoUrl,
      'coverImgUrl': coverImgUrl,
      'aboutMe': aboutMe,
      'mainFeature': mainFeature,
      'lastSpotifySync': lastSpotifySync,
      'reviewStars': reviewStars,
      'isActive': isActive,
      'type': type.name,
      'reason': reason.name,
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
      // 'appMediaItems': appMediaItems,
      'chamberPresets': chamberPresets,
      'watchingEvents': watchingEvents,
      'goingEvents': goingEvents,
      'playingEvents': playingEvents,
      'requests': requests,
      'sentRequests': sentRequests,
      'invitationRequests': invitationRequests,
      'showInDirectory': showInDirectory,
      'isVerified': isVerified,
      'lastNameUpdate': lastNameUpdate,
    };
  }

  AppProfile.fromJSON(data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        photoUrl = data["photoUrl"] ?? "",
        coverImgUrl = data["coverImgUrl"] ?? "",
        type = EnumToString.fromString(ProfileType.values, data["type"] ?? ProfileType.instrumentist.name) ?? ProfileType.instrumentist,
        reason = EnumToString.fromString(UsageReason.values, data["reason"] ?? UsageReason.fun.name) ?? UsageReason.fun,
        aboutMe = data["aboutMe"] ?? "",
        lastSpotifySync = data["lastSpotifySync"] ?? 0,
        reviewStars = data["reviewStars"] ?? 10,
        mainFeature = data["mainFeature"] ?? "",
        isActive = data["isActive"] ?? true,
        position = CoreUtilities.JSONtoPosition(data["position"]),
        address = data["address"] ?? "",
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
        // appMediaItems = data["appMediaItems"]?.cast<String>() ?? [],
        chamberPresets = data["chamberPresets"]?.cast<String>() ?? [],
        watchingEvents = data["watchingEvents"]?.cast<String>() ?? [],
        goingEvents = data["goingEvents"]?.cast<String>() ?? [],
        playingEvents = data["playingEvents"]?.cast<String>() ?? [],
        requests = data["requests"]?.cast<String>() ?? [],
        sentRequests = data["sentRequests"]?.cast<String>() ?? [],
        invitationRequests = data["invitationRequests"]?.cast<String>() ?? [],
        showInDirectory = data["showInDirectory"] ?? false,
        isVerified = data['isVerified'] ?? false,
        lastNameUpdate = data["lastNameUpdate"] ?? 0;

  AppProfile.fromProfileInstruments(data) :
        id = data["id"] ?? "",
        name = data["name"] ?? "",
        photoUrl = data["photoUrl"] ?? "",
        reason = EnumToString.fromString(UsageReason.values, data["reason"] ?? UsageReason.fun.name) ?? UsageReason.fun,
        aboutMe = data["aboutMe"] ?? "",
        mainFeature = data["mainFeature"] ?? "",
        position = CoreUtilities.JSONtoPosition(data["position"]),
        address = data["address"] ?? "",
        favoriteItems = data["favoriteItems"]?.cast<String>() ?? [],
        chamberPresets = data["chamberPresets"]?.cast<String>() ?? [],
        instruments = { for (var e in data["instruments"]?.cast<String>() ?? []) e : Instrument() },
        frequencies = { for (var e in data["frequencies"]?.cast<String>() ?? []) e : NeomFrequency() },
        type = ProfileType.instrumentist, coverImgUrl = "",
        isActive = true,
        showInDirectory = false,
        isVerified = data['isVerified'] ?? false;


  Map<String, dynamic> toProfileInstrumentsJSON() {
    AppUtilities.logger.d("Profile toJSON for Firestore with no Id");
    return <String, dynamic>{
      'id': id,
      'name': name,
      'position': jsonEncode(position),
      'photoUrl': photoUrl,
      'aboutMe': aboutMe,
      'reason': reason.name,
      // 'appMediaItems': appMediaItems,
      'chamberPresets': chamberPresets,
      'genres': genres?.values.map((genre) => genre.name).toList(),
      'mainFeature': mainFeature,
      'instruments': instruments?.values.map((instrument) => instrument.name).toList(),
      'frequencies': frequencies?.values.map((frequency) => frequency.name).toList(),
      'isVerified': isVerified
    };
  }

}
