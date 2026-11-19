import 'package:neom_core/data/api/app_accounts.dart';
import 'package:neom_core/data/api/app_platform_api.dart';
import 'dart:core';

import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../cloud_properties.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/item_list.dart';
import '../../domain/use_cases/mate_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/neom_error_logger.dart';
import '../firestore/itemlist_firestore.dart';
import '../firestore/mate_firestore.dart';
import '../firestore/profile_firestore.dart';

class MateController extends SintController implements MateService {
  
  final userServiceImpl = Sint.find<UserService>();
  AppProfile profile = AppProfile();

  final RxMap<String, AppProfile> _mates = <String, AppProfile>{}.obs;
  final RxMap<String, Map<String, dynamic>> repertoireMatchMeta =
      <String, Map<String, dynamic>>{}.obs;
  final RxMap<String, AppProfile> _followingProfiles = <String, AppProfile>{}.obs;
  final RxMap<String, AppProfile> _followerProfiles = <String, AppProfile>{}.obs;
  final RxMap<String, AppProfile> _profiles = <String, AppProfile>{}.obs;
  final RxString address = "".obs;
  final RxDouble distance = 0.0.obs;
  final RxMap<String, AppMediaItem> totalItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppProfile> _totalProfiles = <String, AppProfile>{}.obs;
  final RxBool following = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  List<String> mateIds = [];
  String mateId = "";

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Mate Controller");
    try {

      profile = userServiceImpl.profile;

      if (SintRoot.treeInitialized) {
        if (Sint.arguments != null && Sint.arguments is List<String>) {
          if (Sint.arguments.isNotEmpty) {
            mateIds = Sint.arguments;
          }
        }
      }

      loadMateProfiles();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'onInit');
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.d("Mate Controller Ready");
  }

  Future<void> loadMateProfiles() async {
    try {
      if(mateIds.isEmpty) {
        if (AppConfig.instance.appInUse == AppInUse.g) {
          await loadItemmates();
        }
        await loadProfiles();
      } else {
        await loadMatesFromList(mateIds);
      }

      _totalProfiles.addAll(_mates);
      _totalProfiles.addAll(_profiles);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadMateProfiles');
    }

    isLoading.value = false;
    update();
  }

  Future<void> loadItemmates() async {
    if (profile.id.isEmpty) return;

    if (AppPlatformApi.isEnabled) {
      try {
        final result = await AppPlatformApi.client('profiles').read<List<Map<String, dynamic>>>(
          'findRepertoireMatches',
          {'profileId': profile.id, 'limit': 50},
          decode: (res) {
            final raw = res['items'] as List? ?? const [];
            return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          },
          fallback: () async => <Map<String, dynamic>>[],
          referenceIds: (_) => const [],
        );
        _applyRepertoireMatches(result);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadItemmates');
      }
      return;
    }

    await _loadItemmatesFromFirebase();
  }

  void _applyRepertoireMatches(List<Map<String, dynamic>> result) {
    final matchedProfiles = <String, AppProfile>{};
    final metaMap = <String, Map<String, dynamic>>{};
    for (final item in result) {
      final p = AppProfile.fromJSON(item);
      if (p.id.isEmpty) continue;
      matchedProfiles[p.id] = p;
      metaMap[p.id] = {
        'matchedCount': item['matchedCount'] ?? 0,
        'totalCallerSongs': item['totalCallerSongs'] ?? 0,
        'matchPercentage': item['matchPercentage'] ?? 0,
        'commonSongs': item['commonSongs'] ?? const [],
        'instruments': item['instruments'] ?? const [],
      };
    }
    _mates.value = matchedProfiles;
    repertoireMatchMeta.value = metaMap;
    profile.itemmates = matchedProfiles.keys.toList();
  }

  Future<void> _loadItemmatesFromFirebase() async {
    try {
      // 1. Prefer server-side Cloud Function when deployed.
      final cloudRes = await CloudProperties.findRepertoireMatchesViaCloud(
        profileId: profile.id,
        limit: 50,
      );
      if (cloudRes != null && cloudRes['items'] is List) {
        final rawItems = (cloudRes['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _applyRepertoireMatches(rawItems);
        return;
      }

      // 2. Direct Firestore fallback: match across public Giglists & legacy
      //    repertoire lists using the exact same canonical song key as the server.
      final repo = ItemlistFirestore();
      final callerLists = Map<String, Itemlist>.from(profile.itemlists ?? {});
      if (callerLists.isEmpty) {
        callerLists.addAll(await repo.getByOwnerId(profile.id));
        profile.itemlists = Map<String, Itemlist>.from(callerLists);
      }

      final callerSongs = <String, Map<String, String>>{};
      final callerRawIds = <String, String>{};

      void registerSong(
        Map<String, Map<String, String>> canonicalMap,
        Map<String, String> rawMap,
        String rawId,
        String name,
        String artist,
        String imgUrl,
      ) {
        final cleanId = rawId.trim();
        if (cleanId.isEmpty) return;
        final mKey = CoreUtilities.normalizeSongMatchKey(name, artist);
        final canonicalKey = mKey.isNotEmpty ? 'mk:$mKey' : 'id:$cleanId';
        canonicalMap.putIfAbsent(
          canonicalKey,
          () => {
            'id': cleanId,
            'name': name.isNotEmpty ? name : cleanId,
            'artist': artist,
            'imgUrl': imgUrl,
          },
        );
        rawMap[cleanId] = canonicalKey;
      }

      void collectFromList(
        Itemlist list,
        Map<String, Map<String, String>> canonicalMap,
        Map<String, String> rawMap,
      ) {
        for (final ext in list.externalItems ?? const []) {
          registerSong(canonicalMap, rawMap, ext.id, ext.name, ext.ownerName, ext.imgUrl);
        }
        for (final med in list.appMediaItems ?? const []) {
          registerSong(canonicalMap, rawMap, med.id, med.name, med.ownerName, med.imgUrl);
        }
        for (final rel in list.appReleaseItems ?? const []) {
          registerSong(canonicalMap, rawMap, rel.id, rel.name, rel.ownerName, rel.imgUrl);
        }
      }

      // Prefer Giglists first; include legacy playlists containing external items
      final callerRepertoireLists = callerLists.values.where(
        (l) =>
            l.type == ItemlistType.giglist ||
            (l.externalItems?.isNotEmpty ?? false) ||
            l.type == ItemlistType.playlist,
      );
      for (final list in callerRepertoireLists) {
        collectFromList(list, callerSongs, callerRawIds);
      }
      for (final favId in profile.favoriteItems ?? const <String>[]) {
        if (!callerRawIds.containsKey(favId)) {
          registerSong(callerSongs, callerRawIds, favId, '', '', '');
        }
      }

      final totalCallerSongs = callerSongs.length;
      if (totalCallerSongs == 0) return;

      final publicGiglists = await repo.fetchAll(
        onlyPublic: true,
        maxLength: 100,
        excludeFromProfileId: profile.id,
        itemlistType: ItemlistType.giglist,
      );
      final publicPlaylists = await repo.fetchAll(
        onlyPublic: true,
        maxLength: 100,
        excludeFromProfileId: profile.id,
        itemlistType: ItemlistType.playlist,
      );

      final listsByOwner = <String, List<Itemlist>>{};
      for (final list in [...publicGiglists.values, ...publicPlaylists.values]) {
        if (list.ownerId.isEmpty || list.ownerId == profile.id) continue;
        if (list.type != ItemlistType.giglist &&
            (list.externalItems?.isEmpty ?? true) &&
            (list.appMediaItems?.isEmpty ?? true)) {
          continue;
        }
        listsByOwner.putIfAbsent(list.ownerId, () => []).add(list);
      }
      if (listsByOwner.isEmpty) return;

      final candidateMatches = <String, List<Map<String, String>>>{};
      for (final entry in listsByOwner.entries) {
        final candSongs = <String, Map<String, String>>{};
        final candRawIds = <String, String>{};
        for (final list in entry.value) {
          collectFromList(list, candSongs, candRawIds);
        }
        if (candSongs.isEmpty) continue;

        final common = <Map<String, String>>[];
        for (final songEntry in callerSongs.entries) {
          final canonicalKey = songEntry.key;
          final songInfo = songEntry.value;
          final matched = candSongs.containsKey(canonicalKey) ||
              candRawIds.containsKey(songInfo['id']);
          if (matched) {
            common.add(songInfo);
          }
        }
        if (common.isNotEmpty) {
          candidateMatches[entry.key] = common;
        }
      }
      if (candidateMatches.isEmpty) return;

      final candidateProfiles = await AppProfiles.repository.retrieveFromList(
        candidateMatches.keys.toList(),
      );

      final ranked = <MapEntry<AppProfile, Map<String, dynamic>>>[];
      for (final entry in candidateMatches.entries) {
        final prof = candidateProfiles[entry.key];
        if (prof == null || prof.id.isEmpty) continue;
        final common = entry.value;
        final pct = ((common.length / totalCallerSongs) * 100).round().clamp(0, 100);
        ranked.add(
          MapEntry(prof, {
            'matchedCount': common.length,
            'totalCallerSongs': totalCallerSongs,
            'matchPercentage': pct,
            'commonSongs': common.take(10).toList(),
            'instruments': prof.instruments?.keys.toList() ?? const [],
          }),
        );
      }

      ranked.sort((a, b) {
        final countCmp = (b.value['matchedCount'] as int)
            .compareTo(a.value['matchedCount'] as int);
        if (countCmp != 0) return countCmp;
        return (b.value['matchPercentage'] as int)
            .compareTo(a.value['matchPercentage'] as int);
      });

      final matchedProfiles = <String, AppProfile>{};
      final metaMap = <String, Map<String, dynamic>>{};
      for (final entry in ranked.take(50)) {
        matchedProfiles[entry.key.id] = entry.key;
        metaMap[entry.key.id] = entry.value;
      }
      _mates.value = matchedProfiles;
      repertoireMatchMeta.value = metaMap;
      profile.itemmates = matchedProfiles.keys.toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: '_loadItemmatesFromFirebase',
      );
    }
  }

  @override
  Future<void> loadMates() async {
    AppConfig.logger.d("loadMates");

    try {
      if(profile.itemmates?.isNotEmpty ?? false) {
        _mates.value = await MateFirestore().getMatesFromList(profile.itemmates!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadMates');
    }

    isLoading.value = false;
    update();
  }

  Future<void> loadFollowingProfiles() async {
    AppConfig.logger.d("loadFollowingProfiles");

    try {
      if(profile.following?.isNotEmpty ?? false) {
        _followingProfiles.value = await MateFirestore().getMatesFromList(profile.following!);
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadFollowingProfiles');
    }

    isLoading.value = false;
    AppConfig.logger.d("${_followingProfiles.length} followingProfiles  found ");
  }

  Future<void> loadFollowersProfiles() async {
    AppConfig.logger.d("");

    try {
      if(profile.followers?.isNotEmpty ?? false) {
        _followerProfiles.value = await MateFirestore().getMatesFromList(profile.followers!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadFollowersProfiles');
    }

    isLoading.value = false;
    AppConfig.logger.d("${_followingProfiles.length} followingProfiles  found ");
  }

  @override
  Future<void> loadMatesFromList(List<String> mateIds) async {
    AppConfig.logger.t("Load ${mateIds.length} mates from List");

    try {
      _mates.value = await MateFirestore().getMatesFromList(mateIds);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadMatesFromList');
    }

    AppConfig.logger.d("${_mates.length} mates found ");
    isLoading.value = false;
  }

  void clear() {
    _mates.value = <String, AppProfile>{};
  }

  @override
  Future<void> getMateDetails(AppProfile mate) async {
    AppConfig.logger.t("getMateDetails: ${mate.id} - ${mate.name}");
    if(mate.id != profile.id) {
      Sint.toNamed(AppRouteConstants.matePath(mate.id), arguments: mate.id);
    } else {
      Sint.toNamed(AppRouteConstants.profilePath(mate.id), arguments: mate.id);
    }
  }

  @override
  Future<void> loadProfiles({bool includeSelf = false, bool loadAll = false}) async {
    AppConfig.logger.d("loadProfiles loadAll: $loadAll, current: ${_profiles.length}");
    try {
      if(_profiles.isEmpty || loadAll) {

        if(loadAll) {
          _profiles.value = await AppProfiles.repository.retrieveAllProfiles();
          AppConfig.logger.d("Loaded ${_profiles.length} profiles (loadAll)");
        } else {
          // Collect all unique profile IDs we need
          final Set<String> neededProfileIds = {};

          if (profile.followers?.isNotEmpty ?? false) {
            neededProfileIds.addAll(profile.followers!);
          }
          if (profile.following?.isNotEmpty ?? false) {
            neededProfileIds.addAll(profile.following!);
          }
          if (profile.itemmates?.isNotEmpty ?? false) {
            neededProfileIds.addAll(profile.itemmates!);
          }

          // Only fetch needed profiles instead of ALL profiles
          if (neededProfileIds.isNotEmpty) {
            _profiles.value = await AppProfiles.repository.retrieveFromList(neededProfileIds.toList());
            AppConfig.logger.d("Loaded ${_profiles.length} needed profiles (instead of all)");
          }
        }

      }

      if(!includeSelf) _profiles.remove(profile.id);

      if((profile.followers?.isNotEmpty ?? false) && _profiles.isNotEmpty) {
        _followerProfiles.value = _profiles.entries
            .where((entry) => profile.followers!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

      if((profile.following?.isNotEmpty ?? false) && _profiles.isNotEmpty) {
        _followingProfiles.value = _profiles.entries
            .where((entry) => profile.following!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

      if ((profile.itemmates?.isNotEmpty ?? false) &&
          _profiles.isNotEmpty &&
          _mates.isEmpty) {
        _mates.value = _profiles.entries
            .where((entry) => profile.itemmates!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadProfiles');
    }

    isLoading.value = false;
    _totalProfiles.value = _profiles.value;
    AppConfig.logger.d("${_totalProfiles.length} profiles found ");
    update();
  }


  @override
  Future<void> block(String profileId) async {
    AppConfig.logger.d("Block Mate: $profileId");
    try {
      if (await ProfileFirestore().blockProfile(profileId: profile.id, profileToBlock: mateId)) {
        userServiceImpl.profile.following!.remove(profileId);
        following.value = false;
        userServiceImpl.profile.blockTo!.add(profileId);

        AppConfig.logger.i("Profile $profileId blocked successfully. You can unblock it later.");
      } else {
        AppConfig.logger.i("Something happened while blocking profile");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'block');
    }

    Sint.back();
    update();
  }

  Future<void> unblock(String profileId) async {
    AppConfig.logger.d("Unblock Mate: $profileId");

    try {
      if (await ProfileFirestore().unblockProfile(profileId: userServiceImpl.profile.id, profileToUnblock:  profileId)) {
        userServiceImpl.profile.blockTo!.remove(profileId);

      } else {
        AppConfig.logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'unblock');
    }

    Sint.back();
    update();
  }

  @override
  Map<String, AppProfile> get mates => _mates.value;

  @override
  Map<String, AppProfile> get followerProfiles => _followerProfiles.value;

  @override
  Map<String, AppProfile> get followingProfiles => _followingProfiles.value;

  @override
  Map<String, AppProfile> get profiles => _profiles.value;

  @override
  Map<String, AppProfile> get totalProfiles => _totalProfiles.value;
}
