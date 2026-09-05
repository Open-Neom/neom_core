import '../domain/model/app_profile.dart';

/// Pure privacy policy used by profile-directory/search reads.
abstract final class ProfileDirectoryPolicy {
  static bool canList(AppProfile profile, {required bool isPublicReader}) =>
      !isPublicReader || profile.directoryVisible;

  static AppProfile applyFieldRedactions(
    AppProfile profile, {
    required bool isPublicReader,
  }) {
    if (isPublicReader) profile.email = '';
    if (!profile.showPhone) profile.phoneNumber = '';
    return profile;
  }

  /// Builds the minimal profile shape that public routes may consume.
  ///
  /// A copy is returned so a guest read cannot poison an authenticated cache
  /// by clearing fields on the source object.
  static AppProfile publicProjection(AppProfile source) {
    if (!source.directoryVisible) return AppProfile();

    final profile = AppProfile.fromJSON(source.toJSON())..id = source.id;

    profile.email = '';
    profile.position = null;
    profile.address = '';
    profile.lastTimeOn = 0;
    profile.isActive = false;

    if (!profile.showPhone) profile.phoneNumber = '';

    profile.itemmates = <String>[];
    profile.eventmates = <String>[];
    profile.followers = <String>[];
    profile.following = <String>[];
    profile.unfollowing = <String>[];
    profile.blockTo = <String>[];
    profile.blockedBy = <String>[];
    profile.posts = <String>[];
    profile.blogEntries = <String>[];
    profile.comments = <String>[];
    profile.hiddenPosts = <String>[];
    profile.hiddenComments = <String>[];
    profile.bannedGenres = <String>[];
    profile.reports = <String>[];
    profile.collectives = <String>[];
    profile.events = <String>[];
    profile.reviews = <String>[];
    profile.favoriteItems = <String>[];
    profile.savedItemlistIds = <String>[];
    profile.chamberPresets = <String>[];
    profile.watchingEvents = <String>[];
    profile.goingEvents = <String>[];
    profile.playingEvents = <String>[];
    profile.requests = <String>[];
    profile.sentRequests = <String>[];
    profile.invitationRequests = <String>[];

    profile.itemlists = {};
    profile.giglists = {};
    profile.chambers = {};
    profile.frequencies = {};
    profile.facilities = {};
    profile.places = {};

    profile.totalTipsReceived = 0;
    profile.lastNameUpdate = 0;
    return profile;
  }
}
