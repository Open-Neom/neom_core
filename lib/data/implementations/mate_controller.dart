import 'dart:core';

import 'package:get/get.dart';

import '../../app_config.dart';
import '../../data/implementations/user_controller.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/use_cases/geolocator_service.dart';
import '../../domain/use_cases/mate_service.dart';
import '../../utils/constants/app_route_constants.dart';
import '../firestore/mate_firestore.dart';
import '../firestore/profile_firestore.dart';
import 'geolocator_controller.dart';

class MateController extends GetxController implements MateService {
  
  final userController = Get.find<UserController>();
  AppProfile profile = AppProfile();

  final RxMap<String, AppProfile> mates = <String, AppProfile>{}.obs;
  final RxMap<String, AppProfile> followingProfiles = <String, AppProfile>{}.obs;
  final RxMap<String, AppProfile> followerProfiles = <String, AppProfile>{}.obs;
  final RxMap<String, AppProfile> profiles = <String, AppProfile>{}.obs;
  final RxString address = "".obs;
  final RxDouble distance = 0.0.obs;
  final RxMap<String, AppMediaItem> totalItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppProfile> totalProfiles = <String, AppProfile>{}.obs;
  final RxBool following = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  GeoLocatorService geoLocatorService = GeoLocatorController();

  List<String> mateIds = [];
  String mateId = "";

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Mate Controller");
    try {

      profile = userController.profile;

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
        ///TODO Implement once algorithm of itemmates and eventmates is available.
        //await loadItemmates();
        await loadProfiles();
      } else {
        await loadMatesFromList(mateIds);
      }

      ///TODO Implement once algorithm of itemmates and eventmates is available.
      //totalProfiles.addAll(itemmates);
      totalProfiles.addAll(profiles);
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
        mates.value = await MateFirestore().getMatesFromList(profile.itemmates!);
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
        followingProfiles.value = await MateFirestore().getMatesFromList(profile.following!);
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    AppConfig.logger.d("${followingProfiles.length} followingProfiles  found ");
    update();
  }

  Future<void> loadFollowersProfiles() async {
    AppConfig.logger.d("");

    try {
      if(profile.followers?.isNotEmpty ?? false) {
        followerProfiles.value = await MateFirestore().getMatesFromList(profile.followers!);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    AppConfig.logger.d("${followingProfiles.length} followingProfiles  found ");
    update();
  }

  @override
  Future<void> loadMatesFromList(List<String> mateIds) async {
    AppConfig.logger.t("Load ${mateIds.length} mates from List");

    try {
      mates.value = await MateFirestore().getMatesFromList(mateIds);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${mates.length} mates found ");
    isLoading.value = false;
    update();
  }

  void clear() {
    mates.value = <String, AppProfile>{};
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
      profiles.value = await ProfileFirestore().retrieveAllProfiles();

      if(!includeSelf) profiles.remove(profile.id);

      if((profile.followers?.isNotEmpty ?? false) && profiles.isNotEmpty) {
        followerProfiles.value = profiles.entries
            .where((entry) => profile.followers!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

      if((profile.following?.isNotEmpty ?? false) && profiles.isNotEmpty) {
        followingProfiles.value = profiles.entries
            .where((entry) => profile.following!.contains(entry.key))
            .fold(<String, AppProfile>{}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

      if((profile.itemmates?.isNotEmpty ?? false )&& profiles.isNotEmpty) {
        mates.value = profiles.entries
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
    AppConfig.logger.d("${profiles.length} profiles found ");
    update();
  }


  @override
  Future<void> block(String profileId) async {
    AppConfig.logger.d("Block Mate: $profileId");
    try {
      if (await ProfileFirestore().blockProfile(profileId: profile.id, profileToBlock: mateId)) {
        userController.profile.following!.remove(profileId);
        following.value = false;
        userController.profile.blockTo!.add(profileId);

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
      if (await ProfileFirestore().unblockProfile(profileId: userController.profile.id, profileToUnblock:  profileId)) {
        userController.profile.blockTo!.remove(profileId);

      } else {
        AppConfig.logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Get.back();
    update();
  }


}
