import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:neom_jobs/jobs/jobs_firestore.dart';

import '../../../auth/ui/login/login_controller.dart';
import '../../data/firestore/app_analytics_firestore.dart';
import '../../data/implementations/geolocator_controller.dart';
import '../../data/implementations/shared_preference_controller.dart';
import '../../data/implementations/user_controller.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/enums/app_locale.dart';

class AppSettingsController extends GetxController {

  var logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxString _newLanguage = "".obs;
  String get newLanguage => _newLanguage.value;
  set newLanguage(String newLanguage) => _newLanguage.value = newLanguage;

  final Rx<AppLocale> _appLocale = AppLocale.english.obs;
  AppLocale get appLocale => _appLocale.value;
  set appLocale(AppLocale appLocale) => _appLocale.value = appLocale;


  final Rx<LocationPermission> _locationPermission = LocationPermission.whileInUse.obs;
  LocationPermission get locationPermission => _locationPermission.value;
  set locationPermission(LocationPermission locationPermission) => _locationPermission.value = locationPermission;


  @override
  void onInit() async {
    super.onInit();
    logger.d("Settings Controller Init");
    await userController.getProfiles();
    newLanguage = AppTranslationConstants.languageFromLocale(Get.locale!);
    isLoading = false;
    locationPermission = await Geolocator.checkPermission();
  }

  void setNewLanguage(String newLang){
    logger.d("Setting new language as $newLang");
    newLanguage = newLang;
    update([AppPageIdConstants.settingsPrivacy]);
  }

  void setNewLocale(){
    logger.d("Setting new locale");
    appLocale = EnumToString.fromString(AppLocale.values, newLanguage)!;
    bool isAvailable = false;
    Get.back();

    switch(appLocale){
      case AppLocale.english:
        isAvailable = true;
        break;
      case AppLocale.spanish:
        isAvailable = true;
        break;
      case AppLocale.french:
        isAvailable = false;
        break;
      case AppLocale.deutsch:
        isAvailable = false;
        break;
    }

    try {
      isAvailable ? Get.find<SharedPreferenceController>().updateLocale(appLocale)
          : Get.snackbar(AppTranslationConstants.underConstruction.tr,
          AppTranslationConstants.underConstructionMsg.tr,
          snackPosition: SnackPosition.bottom);
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.settingsPrivacy]);
  }

  Future<void> verifyLocationPermission() async {
    logger.d("Verifying and requesting location permission");
    locationPermission = await GeoLocatorController().requestPermission();
    update([AppPageIdConstants.settingsPrivacy]);
  }

  Future<void> runAnalyticJobs() async {
    isLoading = true;
    update([AppPageIdConstants.settingsPrivacy]);

    try {
      await AppAnalyticsFirestore().setUserAnalytics();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading = false;
    logger.d("Analytic Job successfully ran.");
    update([AppPageIdConstants.settingsPrivacy]);
  }

  Future<void> runProfileJobs() async {
    isLoading = true;
    update([AppPageIdConstants.settingsPrivacy]);

    try {
      await JobsFirestore().createProfileInstrumentsCollection();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading = false;
    logger.d("Profile Job successfully ran.");
    update([AppPageIdConstants.settingsPrivacy]);
  }

}
