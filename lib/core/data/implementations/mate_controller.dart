import 'package:get/get.dart';

import '../../domain/model/app_item.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/use_cases/geolocator_service.dart';
import '../../domain/use_cases/mate_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../firestore/mate_firestore.dart';
import '../firestore/profile_firestore.dart';
import 'geolocator_controller.dart';
import 'user_controller.dart';

class MateController extends GetxController implements MateService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final RxMap<String, AppProfile> _mates = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get mates => _mates;
  set mates(Map<String, AppProfile> mates) => _mates.value = mates;

  final RxMap<String, AppProfile> _followingProfiles = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get followingProfiles => _followingProfiles;
  set followingProfiles(Map<String, AppProfile> followingProfiles) => _followingProfiles.value = followingProfiles;

  final RxMap<String, AppProfile> _followerProfiles = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get followerProfiles => _followerProfiles;
  set followerProfiles(Map<String, AppProfile> followerProfiles) => _followerProfiles.value = followerProfiles;

  final RxMap<String, AppProfile> _profiles = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get profiles => _profiles;
  set profiles(Map<String, AppProfile> profiles) => _profiles.value = profiles;

  AppProfile profile = AppProfile();

  final RxString _address = "".obs;
  String get address => _address.value;
  set address(String address) => _address.value = address;

  final RxDouble _distance = 0.0.obs;
  double get distance => _distance.value;
  set distance(double distance) => _distance.value = distance;

  final RxMap<String, AppItem> _totalItems = <String, AppItem>{}.obs;
  Map<String, AppItem> get totalItems => _totalItems;
  set totalItems(Map<String, AppItem> totalItems) => _totalItems.value = totalItems;

  final RxMap<String, AppProfile> _totalProfiles = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get totalProfiles => _totalProfiles;
  set totalProfiles(Map<String, AppProfile> totalProfiles) => _totalProfiles.value = totalProfiles;

  final RxBool _following = false.obs;
  bool get following => _following.value;
  set following(bool following) => _following.value = following;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  GeoLocatorService geoLocatorService = GeoLocatorController();

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  List<String> mateIds = [];
  String mateId = "";

  @override
  void onInit() async {
    super.onInit();
    logger.d("");
    try {

      profile = userController.profile;

      if(Get.arguments != null && Get.arguments is List) {
        if(Get.arguments.isNotEmpty) {
          mateIds = Get.arguments;
        }
      }

      if(mateIds.isEmpty) {
        //TODO Implement once algorithm of itemmates and eventmates is available.
        //await loadItemmates();
        await loadProfiles();
      } else {
        await loadMatesFromList(mateIds);
      }


      //totalProfiles.addAll(itemmates);
      totalProfiles.addAll(profiles);
    } catch (e) {
      logger.e(e.toString());
    }
  }


  @override
  Future<void> loadMates() async {
    logger.d("");

    try {
      if(profile.itemmates?.isNotEmpty ?? false) {
        mates = await MateFirestore().getMatesFromList(profile.itemmates!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  Future<void> loadFollowingProfiles() async {
    logger.d("");

    try {
      if(profile.following?.isNotEmpty ?? false) {
        followingProfiles = await MateFirestore().getMatesFromList(profile.following!);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    logger.d("${followingProfiles.length} followingProfiles  found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  Future<void> loadFollowersProfiles() async {
    logger.d("");

    try {
      if(profile.followers?.isNotEmpty ?? false) {
        followerProfiles = await MateFirestore().getMatesFromList(profile.followers!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    logger.d("${followingProfiles.length} followingProfiles  found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  @override
  Future<void> loadMatesFromList(List<String> mateIds) async {
    logger.d("");

    try {
      mates = await MateFirestore().getMatesFromList(mateIds);
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${mates.length} mates found ");
    isLoading = false;
    update([AppPageIdConstants.mates, AppPageIdConstants.search,
      AppPageIdConstants.following, AppPageIdConstants.followers, AppPageIdConstants.likes]);
  }


  void clear() {
    mates = <String, AppProfile>{};
  }

  @override
  Map<String, AppProfile> filterByNameOrInstrument(String name) {

    Map<String, AppProfile> filteredProfiles = {};

    try {
      if(name.isNotEmpty) {
        for (var profile in totalProfiles.values) {
          if(profile.name.toLowerCase().contains(name.toLowerCase())
              || profile.mainFeature.toLowerCase().contains(name.toLowerCase())
              || profile.mainFeature.tr.toLowerCase().contains(name.toLowerCase())
          ){
            filteredProfiles[profile.id] = profile;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

     return filteredProfiles;
  }


  @override
  Future<void> getMateDetails(AppProfile mate) async {
    logger.d("");
    if(mate.id != profile.id) {
      Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id);
    } else {
      Get.toNamed(AppRouteConstants.profileDetails, arguments: mate.id);
    }

  }

  @override
  Future<void> loadProfiles() async {
    logger.d("");
    try {
      profiles = await ProfileFirestore().retrieveAllProfiles();
      profiles.remove(profile.id);
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    logger.d("${profiles.length} profiles found ");
    update([AppPageIdConstants.mates, AppPageIdConstants.search]);
  }


  @override
  Future<void> block(String mateId) async {
    logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(
          profileId: profile.id,
          profileToBlock: mateId)) {

        userController.profile.following!.remove(mateId);
        following = false;
        userController.profile.blockTo!.add(mateId);
      } else {
        logger.i("Something happened while blocking profile");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


}
