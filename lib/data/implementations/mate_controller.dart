import 'dart:core';
import 'package:get/get.dart';
import '../../app_config.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/use_cases/geolocator_service.dart';
import '../../domain/use_cases/mate_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/app_route_constants.dart';
import '../firestore/mate_firestore.dart';
import '../firestore/profile_firestore.dart';

class MateController extends GetxController implements MateService {
  
  final userServiceImpl = Get.find<UserService>();
  AppProfile profile = AppProfile();

  final RxMap<String, AppProfile> _mates = <String, AppProfile>{}.obs;
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

  GeoLocatorService geoLocatorServiceImpl = Get.find<GeoLocatorService>();

  List<String> mateIds = [];
  String mateId = "";

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Mate Controller");
    try {

      profile = userServiceImpl.profile;

      if(Get.arguments != null && Get.arguments is List<String>) {
        if(Get.arguments.isNotEmpty) {
          mateIds = Get.arguments;
        }
      }

      loadMateProfiles();
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
        ///TODO Implement once algorithm of mates and eventmates is available.
        //await loadItemmates();
        await loadProfiles();
      } else {
        await loadMatesFromList(mateIds);
      }

      ///TODO Implement once algorithm of itemmates and eventmates is available.
      //totalProfiles.addAll(itemmates);
      _totalProfiles.addAll(_profiles);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
  }

  @override
  Future<void> loadMates() async {
    AppConfig.logger.d("loadMates");

    try {
      if(profile.itemmates?.isNotEmpty ?? false) {
        _mates.value = await MateFirestore().getMatesFromList(profile.itemmates!);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
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

    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    AppConfig.logger.d("${_followingProfiles.length} followingProfiles  found ");
  }

  @override
  Future<void> loadMatesFromList(List<String> mateIds) async {
    AppConfig.logger.t("Load ${mateIds.length} mates from List");

    try {
      _mates.value = await MateFirestore().getMatesFromList(mateIds);
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
      Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id);
    } else {
      Get.toNamed(AppRouteConstants.profileDetails, arguments: mate.id);
    }
  }

  @override
  Future<void> loadProfiles({bool includeSelf = false}) async {
    AppConfig.logger.t("loadProfiles");
    try {
      _profiles.value = await ProfileFirestore().retrieveAllProfiles();

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

      if((profile.itemmates?.isNotEmpty ?? false )&& _profiles.isNotEmpty) {
        _mates.value = _profiles.entries
            .where((entry) => profile.following!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    AppConfig.logger.d("${_profiles.length} profiles found ");
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Get.back();
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Get.back();
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
