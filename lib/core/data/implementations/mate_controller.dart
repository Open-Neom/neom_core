import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../data/implementations/user_controller.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/use_cases/geolocator_service.dart';
import '../../domain/use_cases/mate_service.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
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
    AppUtilities.logger.t("onInit Mate Controller");
    try {

      profile = userController.profile;

      if(Get.arguments != null && Get.arguments is List<String>) {
        if(Get.arguments.isNotEmpty) {
          mateIds = Get.arguments;
        }
      }

      loadMateProfiles();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
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
     AppUtilities.logger.e(e.toString());
   }

 }

  @override
  Future<void> loadMates() async {
    AppUtilities.logger.d("");

    try {
      if(profile.itemmates?.isNotEmpty ?? false) {
        mates.value = await MateFirestore().getMatesFromList(profile.itemmates!);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  Future<void> loadFollowingProfiles() async {
    AppUtilities.logger.d("loadFollowingProfiles");

    try {
      if(profile.following?.isNotEmpty ?? false) {
        followingProfiles.value = await MateFirestore().getMatesFromList(profile.following!);
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    AppUtilities.logger.d("${followingProfiles.length} followingProfiles  found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  Future<void> loadFollowersProfiles() async {
    AppUtilities.logger.d("");

    try {
      if(profile.followers?.isNotEmpty ?? false) {
        followerProfiles.value = await MateFirestore().getMatesFromList(profile.followers!);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    AppUtilities.logger.d("${followingProfiles.length} followingProfiles  found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  @override
  Future<void> loadMatesFromList(List<String> mateIds) async {
    AppUtilities.logger.t("Load ${mateIds.length} mates from List");

    try {
      mates.value = await MateFirestore().getMatesFromList(mateIds);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${mates.length} mates found ");
    isLoading.value = false;
    update([AppPageIdConstants.mates, AppPageIdConstants.search,
      AppPageIdConstants.following, AppPageIdConstants.followers, AppPageIdConstants.likes]);
  }


  void clear() {
    mates.value = <String, AppProfile>{};
  }

  Map<String, AppProfile> filterByName(String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in totalProfiles.values) {
          if(AppUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())){
            filteredProfiles[profile.id] = profile;
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return filteredProfiles;
  }

  @override
  Map<String, AppProfile> filterByNameOrInstrument(String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in totalProfiles.values) {
          if(AppUtilities.normalizeString(profile.name.toLowerCase()).contains(name.toLowerCase())
              || profile.mainFeature.toLowerCase().contains(name.toLowerCase())
              || profile.mainFeature.tr.toLowerCase().contains(name.toLowerCase())
              || profile.address.toLowerCase().contains(name.toLowerCase())
          ){
            filteredProfiles[profile.id] = profile;
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

     return filteredProfiles;
  }


  @override
  Future<void> getMateDetails(AppProfile mate) async {
    AppUtilities.logger.d("");
    if(mate.id != profile.id) {
      Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id);
    } else {
      Get.toNamed(AppRouteConstants.profileDetails, arguments: mate.id);
    }

  }

  @override
  Future<void> loadProfiles({bool includeSelf = false}) async {
    AppUtilities.logger.t("loadProfiles");
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

      ///VERIFY IF NEEDED
      // if(includeAddress) {
      //   Map<String, AppProfile> profilesWithAddress = {};
      //   profiles.forEach((key, value) async {
      //     if(value.position != null) {
      //       String address = await AppUtilities.getAddressFromPlacerMark(value.position!);
      //       if(address.isNotEmpty) {
      //         value.address = address;
      //         profilesWithAddress[key] = value;
      //       }
      //     } else {
      //       profilesWithAddress[key] = value;
      //     }
      //   });
      //
      //   profiles.clear();
      //   profiles = profilesWithAddress;
      // }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    AppUtilities.logger.d("${profiles.length} profiles found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  @override
  Future<void> blockMate(String mateId) async {
    AppUtilities.logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(profileId: profile.id, profileToBlock: mateId)) {
        userController.profile.following!.remove(mateId);
        following.value = false;
        userController.profile.blockTo!.add(mateId);
      } else {
        AppUtilities.logger.i("Something happened while blocking profile");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    
    update([AppPageIdConstants.mate, AppPageIdConstants.profile, AppPageIdConstants.timeline]);
  }

  @override
  Future<void> showBlockProfileAlert(BuildContext context, String postOwnerId) async {
    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.blockProfile.tr,
        content: Column(
          children: [
            Text(AppTranslationConstants.blockProfileMsg.tr,
              style: const TextStyle(fontSize: 15),
            ),
            AppTheme.heightSpace10,
            Text(AppTranslationConstants.blockProfileMsg2.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ],),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              if(!isButtonDisabled.value) {
                await blockMate(postOwnerId);
                Navigator.pop(context);
                Navigator.pop(context);
                AppUtilities.showSnackBar(message: AppTranslationConstants.blockedProfileMsg);
              }
            },
            child: Text(AppTranslationConstants.toBlock.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }
}
