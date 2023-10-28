import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../utils/core_utilities.dart';
import '../../utils/enums/usage_reason.dart';
import 'band_member.dart';
import 'genre.dart';
import 'item_list.dart';
import 'price.dart';
import 'review.dart';

class Band {

  String id;
  String name;
  String description;
  String photoUrl;
  String coverImgUrl;

  UsageReason reason;
  Price? pricePerHour;
  double reviewStars =  10.0;
  Review? lastReview;

  bool isActive;
  int createdTime;
  int lastSession;
  Position? position;

  List<String>? bannedGenres;
  List<String>? itemmates;
  List<String>? eventmates;
  List<String>? followers;
  List<String>? following;
  List<String>? unfollowing;
  List<String>? posts;
  List<String>? hiddenPosts;
  List<String>? hiddenComments;
  List<String>? reports;
  List<String>? events;
  List<String>? reviews;

  List<String>? appMediaItems;
  List<String>? appReleaseItems;
  List<String>? playingEvents;

  List<String>? requests;
  List<String>? sentRequests;
  List<String>? invitationRequests;

  bool isFulfilled = false;

  ///These are retrieved from a Firebase Collection
  Map<String, Itemlist>? itemlists;
  Map<String, Genre>? genres;
  Map<String, BandMember>? bandMembers;

  Band({
    this.id = "",
    this.name = "",
    this.description = "",
    this.photoUrl = "",
    this.coverImgUrl = "",
    this.reason = UsageReason.any,
    this.pricePerHour,
    this.reviewStars = 10.0,
    this.isActive = false,
    this.createdTime = 0,
    this.lastSession = 0,
    this.position,
    this.lastReview,
    this.bannedGenres,
    this.itemmates,
    this.eventmates,
    this.followers,
    this.following,
    this.unfollowing,
    this.posts,
    this.hiddenPosts,
    this.hiddenComments,
    this.reports,
    this.events,
    this.reviews,
    this.playingEvents,
    this.requests,
    this.sentRequests,
    this.invitationRequests
  });

  @override
  String toString() {
    return 'Band{id: $id, name: $name, description: $description, photoUrl: $photoUrl, coverImgUrl: $coverImgUrl, reason: $reason, pricePerHour: $pricePerHour, reviewStars: $reviewStars, lastReview: $lastReview, isActive: $isActive, createdTime: $createdTime, lastSession: $lastSession, position: $position, bannedGenres: $bannedGenres, itemmates: $itemmates, eventmates: $eventmates, followers: $followers, following: $following, unfollowing: $unfollowing, posts: $posts, hiddenPosts: $hiddenPosts, hiddenComments: $hiddenComments, reports: $reports, events: $events, reviews: $reviews, playingEvents: $playingEvents, requests: $requests, sentRequests: $sentRequests, invitationRequests: $invitationRequests, isFulfilled: $isFulfilled, itemlists: $itemlists, genres: $genres, bandMembers: $bandMembers}';
  }

  Map<String, dynamic> toJSON() {
    Get.log("Band toJSON");
    return <String, dynamic> {
      'id': id,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'coverImgUrl': coverImgUrl,
      'reason': reason.name,
      'pricePerHour': pricePerHour?.toJSON() ?? Price().toJSON(),
      'reviewStars': reviewStars,
      'isActive': isActive,
      'createdTime': createdTime,
      'lastSession': lastSession,
      'position': jsonEncode(position),
      'lastReview': lastReview?.toJSON() ?? Review().toJSON(),
      'bannedGenres': bannedGenres,
      'itemmates': itemmates,
      'eventmates': eventmates,
      'followers': followers,
      'following': following,
      'unfollowing': unfollowing,
      'posts': posts,
      'hiddenPosts': hiddenPosts,
      'hiddenComments': hiddenComments,
      'reports': reports,
      'events': events,
      'reviews': reviews,
      'appMediaItems': appMediaItems,
      'appReleaseItems': appReleaseItems,
      'playingEvents': playingEvents,
      'requests': requests,
      'sentRequests': sentRequests,
      'invitationRequests': invitationRequests
    };
  }

  Band.fromJSON(data) :
        id = data["id"],
        name = data["name"],
        description = data["description"] ?? "",
        photoUrl = data["photoUrl"],
        coverImgUrl = data["coverImgUrl"] ?? "",
        reason = EnumToString.fromString(UsageReason.values, data["reason"]) ?? UsageReason.fun,
        pricePerHour = Price.fromJSON(data["pricePerHour"]),
        reviewStars = data["reviewStars"],
        isActive = data["isActive"] ?? true,
        createdTime = data["createdTime"] ?? 0,
        lastSession = data["lastSession"] ?? 0,
        position = CoreUtilities.JSONtoPosition(data["position"]),
        bannedGenres = data["bannedGenres"]?.cast<String>() ?? [],
        itemmates = data["itemmates"]?.cast<String>() ?? [],
        eventmates = data["eventmates"]?.cast<String>() ?? [],
        following = data["following"]?.cast<String>() ?? [],
        followers = data["followers"]?.cast<String>() ?? [],
        unfollowing = data["unfollowing"]?.cast<String>() ?? [],
        posts = data["posts"]?.cast<String>() ?? [],
        hiddenPosts = data["hiddenPosts"]?.cast<String>() ?? [],
        hiddenComments = data["hiddenComments"]?.cast<String>() ?? [],
        reports = data["reports"]?.cast<String>() ?? [],
        events = data["events"]?.cast<String>() ?? [],
        reviews = data["reviews"]?.cast<String>() ?? [],
        appMediaItems = data["appMediaItems"]?.cast<String>() ?? [],
        appReleaseItems = data["appReleaseItems"]?.cast<String>() ?? [],
        playingEvents = data["playingEvents"]?.cast<String>() ?? [],
        requests = data["requests"]?.cast<String>() ?? [],
        sentRequests = data["sentRequests"]?.cast<String>() ?? [],
        invitationRequests = data["invitationRequests"]?.cast<String>() ?? [];

}
