import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/repository/account_profiles_reader.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/profile_directory_repository.dart';
import '../../utils/enums/event_action.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/request_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../../utils/enums/verification_level.dart';
import '../../utils/profile_directory_policy.dart';
import 'app_data_api_client.dart';
import 'data_api_codec.dart';

class AppProfileApi implements ProfileDirectoryRepository {
  AppProfileApi({
    required this.client,
    required this.firebase,
    required this.accounts,
    required this.publicReader,
  });
  final AppDataApiClient client;
  final ProfileDirectoryRepository firebase;
  final AccountRepository accounts;
  final bool Function() publicReader;

  AppProfile _decode(
    dynamic value, {
    required bool public,
    bool owned = false,
  }) {
    if (value is! Map ||
        value['id'] is! String ||
        (value['id'] as String).isEmpty) {
      throw const FormatException('Expected a profile ID');
    }
    final data = profileApiMap(value);
    if (public &&
        (data['visibility'] != 'public' ||
            data['schemaVersion'] != 1 ||
            data['directoryVisible'] != true)) {
      throw const FormatException(
        'Expected a visible public profile projection',
      );
    }
    final profile = AppProfile.fromJSON(data);
    return public
        ? ProfileDirectoryPolicy.publicProjection(profile)
        : owned
        ? profile
        : ProfileDirectoryPolicy.applyFieldRedactions(
            profile,
            isPublicReader: false,
          );
  }

  Future<List<AppProfile>> _profiles(
    String operation,
    Map<String, dynamic> arguments,
    Future<List<AppProfile>> Function() fallback, {
    bool owned = false,
    bool single = false,
  }) {
    final public = !owned && publicReader();
    return client.read(
      operation,
      dataApiValue(arguments) as Map<String, dynamic>,
      private: !public,
      audience: public ? 'public' : 'account',
      fallback: () async {
        final items = await fallback();
        if (!owned && public != publicReader()) {
          throw StateError('Profile audience changed');
        }
        return items
            .where((p) => !public || p.directoryVisible)
            .map(
              (p) => public
                  ? ProfileDirectoryPolicy.publicProjection(p)
                  : owned
                  ? p
                  : ProfileDirectoryPolicy.applyFieldRedactions(
                      AppProfile.fromJSON(p.toJSON()),
                      isPublicReader: false,
                    ),
            )
            .toList();
      },
      referenceIds: (items) => items.map((p) => p.id),
      decode: (response) {
        if (!owned && public != publicReader()) {
          throw StateError('Profile audience changed');
        }
        final items = response['items'];
        if (items is! List || single && items.length > 1) {
          throw const FormatException('Expected profile results');
        }
        return items
            .map((v) => _decode(v, public: public, owned: owned))
            .toList();
      },
    );
  }

  Future<Map<String, AppProfile>> _map(
    String operation,
    Map<String, dynamic> args,
    Future<Map<String, AppProfile>> Function() fallback,
  ) async {
    final items = await _profiles(
      operation,
      args,
      () async => (await fallback()).values.toList(),
    );
    return {for (final item in items) item.id: item};
  }

  Future<AppProfile?> _single(
    String operation,
    Map<String, dynamic> args,
    Future<AppProfile?> Function() fallback,
  ) async {
    final items = await _profiles(operation, args, () async {
      final item = await fallback();
      return item == null || item.id.isEmpty ? [] : [item];
    }, single: true);
    return items.firstOrNull;
  }

  Future<bool> _available(
    String operation,
    Map<String, dynamic> args,
    Future<bool> Function() fallback,
  ) => client.read(
    operation,
    dataApiValue(args) as Map<String, dynamic>,
    private: !publicReader(),
    audience: publicReader() ? 'public' : 'account',
    fallback: fallback,
    referenceIds: (_) => const [],
    decode: (r) => dataApiScalar<bool>(r['value']),
  );
  Future<bool> _write(String operation, Map<String, dynamic> args) async =>
      dataApiScalar<bool>(
        await client.mutate(
          operation,
          dataApiValue(args) as Map<String, dynamic>,
        ),
      );

  @override
  Future<String> insert(String userId, AppProfile profile) async {
    if (userId.isEmpty) throw ArgumentError('Owner account ID required');
    if (profile.id.isEmpty) profile.id = const Uuid().v4();
    final id = dataApiScalar<String>(
      await client.mutate('insert', {
        'userId': userId,
        'profile': profile.toJSON(),
      }),
    );
    if (id != profile.id) {
      throw const FormatException('Unexpected created profile ID');
    }
    return id;
  }

  @override
  Future<List<AppProfile>> retrieveByUserId(String userId) =>
      _profiles('retrieveByUserId', {'userId': userId}, () async {
        final reader = accounts;
        if (reader is AccountProfilesReader) {
          return (reader as AccountProfilesReader).getOwnedProfiles(userId);
        }
        final owner = await accounts.getById(userId, throwOnError: true);
        return owner.profiles;
      }, owned: true);
  @override
  Future<AppProfile?> getBySlug(String slug) {
    if (slug.isEmpty) return Future.value(null);
    return _single('getBySlug', {'slug': slug}, () => firebase.getBySlug(slug));
  }

  @override
  Future<List<AppProfile>> searchByName(String query, {int limit = 20}) {
    if (query.trim().isEmpty || limit <= 0) return Future.value([]);
    return _profiles('searchByName', {
      'query': query,
      'limit': limit,
    }, () => firebase.searchByName(query, limit: limit));
  }

  @override
  Future<QuerySnapshot> handleSearch(String query) =>
      firebase.handleSearch(query);

  @override
  Future<AppProfile> retrieve(String profileId) async =>
      (await _single('retrieve', {
        'profileId': profileId,
      }, () => firebase.retrieve(profileId))) ??
      AppProfile();

  @override
  Future<AppProfile?> retrieveSimple(String profileId) => _single(
    'retrieveSimple',
    {'profileId': profileId},
    () => firebase.retrieveSimple(profileId),
  );

  @override
  Future<AppProfile> retrieveFull(String profileId) async =>
      (await _single('retrieveFull', {
        'profileId': profileId,
      }, () => firebase.retrieveFull(profileId))) ??
      AppProfile();

  @override
  Future<bool> remove({required String userId, required String profileId}) =>
      _write('remove', {'userId': userId, 'profileId': profileId});

  @override
  Future<Map<String, AppProfile>> retrieveAllProfiles({
    int limit = 0,
    bool forceRefresh = false,
  }) => _map(
    'retrieveAllProfiles',
    {'limit': limit, 'forceRefresh': forceRefresh},
    () =>
        firebase.retrieveAllProfiles(limit: limit, forceRefresh: forceRefresh),
  );

  @override
  Future<List<AppProfile>> getWithParameters({
    bool needsPhone = false,
    bool needsPosts = false,
    List<ProfileType>? profileTypes,
    FacilityType? facilityType,
    PlaceType? placeType,
    List<UsageReason>? usageReasons,
    Position? currentPosition,
    int maxDistance = 30,
  }) => _profiles(
    'getWithParameters',
    {
      'needsPhone': needsPhone,
      'needsPosts': needsPosts,
      'profileTypes': profileTypes,
      'facilityType': facilityType,
      'placeType': placeType,
      'usageReasons': usageReasons,
      'currentPosition': currentPosition,
      'maxDistance': maxDistance,
    },
    () => firebase.getWithParameters(
      needsPhone: needsPhone,
      needsPosts: needsPosts,
      profileTypes: profileTypes,
      facilityType: facilityType,
      placeType: placeType,
      usageReasons: usageReasons,
      currentPosition: currentPosition,
      maxDistance: maxDistance,
    ),
  );

  @override
  Future<bool> followProfile({
    required String profileId,
    required String followedProfileId,
  }) => _write('followProfile', {
    'profileId': profileId,
    'followedProfileId': followedProfileId,
  });

  @override
  Future<bool> unfollowProfile({
    required String profileId,
    required String unfollowProfileId,
  }) => _write('unfollowProfile', {
    'profileId': profileId,
    'unfollowProfileId': unfollowProfileId,
  });

  @override
  Future<bool> blockProfile({
    required String profileId,
    required String profileToBlock,
  }) => _write('blockProfile', {
    'profileId': profileId,
    'profileToBlock': profileToBlock,
  });

  @override
  Future<bool> unblockProfile({
    required String profileId,
    required String profileToUnblock,
  }) => _write('unblockProfile', {
    'profileId': profileId,
    'profileToUnblock': profileToUnblock,
  });

  @override
  Future<bool> updatePosition(String profileId, Position newPositionO) =>
      _write('updatePosition', {
        'profileId': profileId,
        'newPositionO': newPositionO,
      });

  @override
  Future<bool> addPost(String profileId, String postId) =>
      _write('addPost', {'profileId': profileId, 'postId': postId});

  @override
  Future<bool> removePost(String profileId, String postId) =>
      _write('removePost', {'profileId': profileId, 'postId': postId});

  @override
  Future<bool> updateName(String profileId, String name) =>
      _write('updateName', {'profileId': profileId, 'name': name});

  @override
  Future<bool> updateSlug(String profileId, String slug) =>
      _write('updateSlug', {'profileId': profileId, 'slug': slug});

  @override
  Future<bool> isAvailableSlug(String slug) => _available('isAvailableSlug', {
    'slug': slug,
  }, () => firebase.isAvailableSlug(slug));

  @override
  Future<bool> updateAboutMe(String profileId, String aboutMe) =>
      _write('updateAboutMe', {'profileId': profileId, 'aboutMe': aboutMe});

  @override
  Future<bool> addEvent(
    String profileId,
    String eventId,
    EventAction eventAction,
  ) => _write('addEvent', {
    'profileId': profileId,
    'eventId': eventId,
    'eventAction': eventAction,
  });

  @override
  Future<bool> removeEvent(
    String profileId,
    String eventId,
    EventAction eventAction,
  ) => _write('removeEvent', {
    'profileId': profileId,
    'eventId': eventId,
    'eventAction': eventAction,
  });

  @override
  Future<bool> addFavoriteItem(String profileId, String itemId) =>
      _write('addFavoriteItem', {'profileId': profileId, 'itemId': itemId});

  @override
  Future<bool> addFavoriteItems(String profileId, List<String> itemIds) =>
      _write('addFavoriteItems', {'profileId': profileId, 'itemIds': itemIds});

  @override
  Future<bool> removeFavoriteItem(String profileId, String itemId) =>
      _write('removeFavoriteItem', {'profileId': profileId, 'itemId': itemId});

  @override
  Future<bool> removeFavoriteItems(String profileId, List<String> itemIds) =>
      _write('removeFavoriteItems', {
        'profileId': profileId,
        'itemIds': itemIds,
      });

  @override
  Future<bool> saveItemlist(String profileId, String itemlistId) =>
      _write('saveItemlist', {'profileId': profileId, 'itemlistId': itemlistId});

  @override
  Future<bool> unsaveItemlist(String profileId, String itemlistId) =>
      _write('unsaveItemlist', {'profileId': profileId, 'itemlistId': itemlistId});

  @override
  Future<Map<String, AppProfile>> getFollowers(String profileId) => _map(
    'getFollowers',
    {'profileId': profileId},
    () => firebase.getFollowers(profileId),
  );

  @override
  Future<Map<String, AppProfile>> getFollowed(String profileId) => _map(
    'getFollowed',
    {'profileId': profileId},
    () => firebase.getFollowed(profileId),
  );

  @override
  Future<bool> updatePhotoUrl(String profileId, String photoUrl) =>
      _write('updatePhotoUrl', {'profileId': profileId, 'photoUrl': photoUrl});

  @override
  Future<bool> updateCoverImgUrl(String profileId, String coverImgUrl) =>
      _write('updateCoverImgUrl', {
        'profileId': profileId,
        'coverImgUrl': coverImgUrl,
      });

  @override
  Future<Map<String, AppProfile>> retrieveProfilesByInstrument({
    String selfProfileId = "",
    Position? currentPosition,
    String instrumentId = "",
    int maxDistance = 20,
    int maxProfiles = 10,
  }) => _map(
    'retrieveProfilesByInstrument',
    {
      'selfProfileId': selfProfileId,
      'currentPosition': currentPosition,
      'instrumentId': instrumentId,
      'maxDistance': maxDistance,
      'maxProfiles': maxProfiles,
    },
    () => firebase.retrieveProfilesByInstrument(
      selfProfileId: selfProfileId,
      currentPosition: currentPosition,
      instrumentId: instrumentId,
      maxDistance: maxDistance,
      maxProfiles: maxProfiles,
    ),
  );

  @override
  Future<Map<String, AppProfile>> retrieveProfilesByFacility({
    required String selfProfileId,
    required Position? currentPosition,
    FacilityType? facilityType,
    int maxDistance = 30,
    int maxProfiles = 30,
  }) => _map(
    'retrieveProfilesByFacility',
    {
      'selfProfileId': selfProfileId,
      'currentPosition': currentPosition,
      'facilityType': facilityType,
      'maxDistance': maxDistance,
      'maxProfiles': maxProfiles,
    },
    () => firebase.retrieveProfilesByFacility(
      selfProfileId: selfProfileId,
      currentPosition: currentPosition,
      facilityType: facilityType,
      maxDistance: maxDistance,
      maxProfiles: maxProfiles,
    ),
  );

  @override
  Future<Map<String, AppProfile>> retrieveProfilesByPlace({
    required String selfProfileId,
    required Position? currentPosition,
    PlaceType? placeType,
    int maxDistance = 30,
    int maxProfiles = 30,
  }) => _map(
    'retrieveProfilesByPlace',
    {
      'selfProfileId': selfProfileId,
      'currentPosition': currentPosition,
      'placeType': placeType,
      'maxDistance': maxDistance,
      'maxProfiles': maxProfiles,
    },
    () => firebase.retrieveProfilesByPlace(
      selfProfileId: selfProfileId,
      currentPosition: currentPosition,
      placeType: placeType,
      maxDistance: maxDistance,
      maxProfiles: maxProfiles,
    ),
  );

  @override
  Future<Map<String, AppProfile>> retrieveFromList(List<String> profileIds) =>
      _map('retrieveFromList', {
        'profileIds': profileIds,
      }, () => firebase.retrieveFromList(profileIds));

  @override
  Future<bool> hidePost(String profileId, String postId) =>
      _write('hidePost', {'profileId': profileId, 'postId': postId});

  @override
  Future<bool> addComment(String profileId, String commentId) =>
      _write('addComment', {'profileId': profileId, 'commentId': commentId});

  @override
  Future<bool> removeComment(String profileId, String commentId) =>
      _write('removeComment', {'profileId': profileId, 'commentId': commentId});

  @override
  Future<bool> hideComment(String profileId, String commentId) =>
      _write('hideComment', {'profileId': profileId, 'commentId': commentId});

  @override
  Future<bool> addCollective({
    required String profileId,
    required String collectiveId,
  }) => _write('addCollective', {
    'profileId': profileId,
    'collectiveId': collectiveId,
  });

  @override
  Future<bool> removeCollective({
    required String profileId,
    required String collectiveId,
  }) => _write('removeCollective', {
    'profileId': profileId,
    'collectiveId': collectiveId,
  });

  @override
  Future<bool> removeRequest(
    String profileId,
    String requestId,
    RequestType requestType,
  ) => _write('removeRequest', {
    'profileId': profileId,
    'requestId': requestId,
    'requestType': requestType,
  });

  @override
  Future<bool> addRequest(
    String profileId,
    String requestId,
    RequestType requestType,
  ) => _write('addRequest', {
    'profileId': profileId,
    'requestId': requestId,
    'requestType': requestType,
  });

  @override
  Future<bool> isAvailableName(String profileName) => _available(
    'isAvailableName',
    {'profileName': profileName},
    () => firebase.isAvailableName(profileName),
  );

  @override
  Future<bool> updateLastSpotifySync(String profileId) =>
      _write('updateLastSpotifySync', {'profileId': profileId});

  @override
  Future<bool> addBlogEntry(String profileId, String blogEntryId) => _write(
    'addBlogEntry',
    {'profileId': profileId, 'blogEntryId': blogEntryId},
  );

  @override
  Future<bool> removeBlogEntry(String profileId, String blogEntryId) => _write(
    'removeBlogEntry',
    {'profileId': profileId, 'blogEntryId': blogEntryId},
  );

  @override
  Future<bool> removeAllFavoriteItems(String profileId) =>
      _write('removeAllFavoriteItems', {'profileId': profileId});

  @override
  Future<bool> addChamberPreset({
    required String profileId,
    required String chamberPresetId,
  }) => _write('addChamberPreset', {
    'profileId': profileId,
    'chamberPresetId': chamberPresetId,
  });

  @override
  Future<bool> updateAddress(String profileId, String address) =>
      _write('updateAddress', {'profileId': profileId, 'address': address});

  @override
  Future<bool> updatePhoneNumber(String profileId, String phoneNumber) =>
      _write('updatePhoneNumber', {
        'profileId': profileId,
        'phoneNumber': phoneNumber,
      });

  @override
  Future<bool> updateType(String profileId, ProfileType type) =>
      _write('updateType', {'profileId': profileId, 'type': type});

  @override
  Future<bool> updateVerificationLevel(
    String profileId,
    VerificationLevel verificationLevel,
  ) => _write('updateVerificationLevel', {
    'profileId': profileId,
    'verificationLevel': verificationLevel,
  });

  @override
  Future<AppProfile?> getByEmail(String email) {
    if (publicReader()) return Future.value(null);
    return _single('getByEmail', {
      'email': email,
    }, () => firebase.getByEmail(email));
  }
}
