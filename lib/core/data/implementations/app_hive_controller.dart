import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/model/app_release_item.dart';
import '../../domain/model/item_list.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/enums/app_hive_box.dart';
import '../../utils/enums/app_locale.dart';
import 'user_controller.dart';


class AppHiveController {

  static final AppHiveController _instance = AppHiveController._internal();
  factory AppHiveController() {
    _instance._init();
    return _instance;
  }

  AppHiveController._internal();

  bool _isInitialized = false;

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    AppUtilities.logger.t('AppHive Controller Initialization');

    try {
      // await Hive.initFlutter();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  final userController = Get.find<UserController>();
  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  //SEARCH Cache
  List searchedList = [];
  List searchQueries = [];

  //RELEASES CACHE
  Map<String, AppReleaseItem> mainItems = {};
  Map<String, AppReleaseItem> secondaryItems = {};
  Map<String, Itemlist> releaseItemlists = {};
  String releaseLastUpdate = '';
  String directoryLastUpdate = '';

  Future<Box> getBox(String boxName, {bool limit = false}) async {
    return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await openHiveBox(boxName, limit: limit);
  }

  Future<Box> openHiveBox(String boxName, {bool limit = false}) async {
    AppUtilities.logger.t('openHiveBox $boxName');
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      AppUtilities.logger.e('Failed to open $boxName Box');
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      final File dbFile = File('$dirPath/$boxName.hive');
      final File lockFile = File('$dirPath/$boxName.lock');

      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });

    if (limit && box.length > 500) {
      AppUtilities.logger.w("Box $boxName would be cleared as it exceeded the limit");
      box.clear();
    }

    return box;
  }

  Future<void> clearBox(String boxName) async {
    Box box = await getBox(boxName);
    box.clear();
  }

  // Shared Preference Migration to Hive
  Future<void> fetchProfileInfo() async {
    AppUtilities.logger.d('fetchProfileInfo');

    final profileBox = await getBox(AppHiveBox.profile.name);
    userController.user.id = profileBox.get(AppHiveConstants.userId, defaultValue: '');
    userController.user.name = profileBox.get(AppHiveConstants.username, defaultValue: '');
    userController.profile.id = profileBox.get(AppHiveConstants.profileId, defaultValue: '');
    userController.profile.aboutMe = profileBox.get(AppHiveConstants.aboutMe, defaultValue: '');
    userController.profile.photoUrl = profileBox.get(AppHiveConstants.photoUrl, defaultValue: '');
    firstTime = profileBox.get(AppHiveConstants.firstTime, defaultValue: true);
    lastNotificationCheckDate = profileBox.get(AppHiveConstants.lastNotificationCheckDate, defaultValue: 0);

    final savedLocale = profileBox.get(AppHiveConstants.appLocale, defaultValue: 'spanish');
    if(savedLocale.isNotEmpty) {
      setLocale(EnumToString.fromString(AppLocale.values, savedLocale)!);
    } else {
      AppLocale appLocale = AppLocale.spanish;

      switch(Get.locale?.languageCode ?? "") {
        case "es":
          appLocale = AppLocale.spanish;
          break;
        case "en":
          appLocale = AppLocale.english;
          break;
        case "":
          break;

      }
      setLocale(appLocale);
      updateLocale(appLocale);
    }

    // await profileBox.close();

  }

  Future<void> writeProfileInfo() async {
    final box = await getBox(AppHiveBox.profile.name);
    await box.put(AppHiveConstants.userId, userController.user.id);
    await box.put(AppHiveConstants.username, userController.user.name);
    await box.put(AppHiveConstants.profileId, userController.profile.id);
    await box.put(AppHiveConstants.photoUrl, userController.user.photoUrl);
    await box.put(AppHiveConstants.firstTime, false);
    // await box.close();
  }

  Future<void> fetchCachedData() async {
    AppUtilities.logger.d('fetchCachedData');
    // Usa un cast seguro (as Map<dynamic, dynamic>?) y el operador ?.
    final releasesBox = await getBox(AppHiveBox.releases.name);

    mainItems = await compute<Map<String, dynamic>, Map<String, AppReleaseItem>>(
        _mapToReleaseItem,
        Map<String, dynamic>.from(releasesBox.get(AppHiveConstants.mainItems) ?? {})
    );

    secondaryItems = await compute<Map<String, dynamic>, Map<String, AppReleaseItem>>(
        _mapToReleaseItem,
        Map<String, dynamic>.from(releasesBox.get(AppHiveConstants.secondaryItems) ?? {})
    );

    // final rawMainItems = releasesBox.get(AppHiveConstants.mainItems) as Map<dynamic, dynamic>?;
    // mainItems = rawMainItems?.map((key, value) => MapEntry(key, AppReleaseItem.fromJSON(value))) ?? {};
    //
    // final rawSecondaryItems = releasesBox.get(AppHiveConstants.secondaryItems) as Map<dynamic, dynamic>?;
    // secondaryItems = rawSecondaryItems?.map((key, value) => MapEntry(key, AppReleaseItem.fromJSON(value))) ?? {};


// De igual forma para releaseItemlists:
    final rawReleaseItemLists = releasesBox.get(AppHiveConstants.releaseItemLists) as Map<dynamic, dynamic>?;
    releaseItemlists = rawReleaseItemLists?.map((key, value) => MapEntry(key, Itemlist.fromJSON(value))) ?? {};

    final rawReleaseLastUpdate = releasesBox.get(AppHiveConstants.lastUpdate) as String?;
    releaseLastUpdate = rawReleaseLastUpdate ?? '';


    final directoryBox = await getBox(AppHiveBox.directory.name);
    final rawDirectoryLastUpdate = directoryBox.get(AppHiveConstants.lastUpdate) as String?;
    directoryLastUpdate = rawDirectoryLastUpdate ?? '';

    // await releasesBox.close();
    // await directoryBox.close();
  }

  Map<String, AppReleaseItem> _mapToReleaseItem(Map<dynamic, dynamic> rawItems) {
    return rawItems.map((key, value) => MapEntry(key.toString(), AppReleaseItem.fromJSON(value)));
  }

  Future<void> fetchSettingsData() async {
    AppUtilities.logger.d('fetchSettingsData');
    final settingsBox = await getBox(AppHiveBox.settings.name);
    searchQueries = settingsBox.get(AppHiveConstants.searchQueries, defaultValue: []) as List;
    // await settingsBox.close();
  }

  Future<void> setSearchQueries(List searchQueries) async {
    AppUtilities.logger.d('setSearchQueries');
    final settingsBox = await getBox(AppHiveBox.settings.name);
    await settingsBox.put(AppHiveConstants.searchQueries, searchQueries);
    // await settingsBox.close();
  }

  Future<void> addQuery(String query) async {
    try {
      final settingsBox = await getBox(AppHiveBox.settings.name);
      query = query.trim();
      List searchQueries = settingsBox.get(AppHiveConstants.search, defaultValue: [],) as List;
      final idx = searchQueries.indexOf(query);
      if (idx != -1) searchQueries.removeAt(idx);
      searchQueries.insert(0, query);
      if (searchQueries.length > 10) searchQueries = searchQueries.sublist(0, 10);
      await settingsBox.put(AppHiveConstants.search, searchQueries);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Future<void> saveMainItem(AppReleaseItem item) async {
    mainItems[item.id] = item;
    final releaseBox = await getBox(AppHiveBox.releases.name);
    await releaseBox.put(AppHiveConstants.mainItems, mainItems);
    // await releaseBox.close();

  }

  Future<File?> getCachedPdf(String id) async {
    final pdfCacheBox = await getBox(AppHiveBox.pdfCache.name);
    if (pdfCacheBox != null) {
      final String? cachedPath = pdfCacheBox.get(id);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return File(cachedPath);
      }
    }
    return null;
  }

  /// Guarda la ruta del archivo PDF en el caché usando la URL como key
  Future<void> cachePdf(String id, File file) async {
    final pdfCacheBox = await getBox(AppHiveBox.pdfCache.name);
    if (pdfCacheBox != null) {
      await pdfCacheBox.put(id, file.path);
    }
  }

  @override
  Future<void> updateLocale(AppLocale appLocale) async {
    AppUtilities.logger.d("Setting locale preference to ${appLocale.name}");

    try {
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.appLocale, appLocale.name);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void setLocale(AppLocale appLocale) {
    AppUtilities.logger.d("Updating GetX locale to ${appLocale.name}");

    Locale locale = Get.deviceLocale!;

    switch(appLocale) {
      case AppLocale.english:
        locale = const Locale('en');
        break;
      case AppLocale.spanish:
        locale = const Locale('es');
        break;
      case AppLocale.french:
        locale = const Locale('fr');
        break;
      case AppLocale.deutsch:
        locale = const Locale('de');
        break;
    }

    Get.updateLocale(locale);
  }

  @override
  Future<void> setFirstTime(bool fTime) async {
    AppUtilities.logger.t("Setting firsTime to $firstTime");

    try {
      firstTime = fTime;
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.firstTime, fTime);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<void> setLastNotificationCheckDate(int lastNotificationCheckDate) async {
    AppUtilities.logger.d("Setting last time notification were checked");

    try {
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.lastNotificationCheckDate, lastNotificationCheckDate);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  Future<void> setLastIndexPos({required int? lastIndex, required int lastPos}) async {
    AppUtilities.logger.d("Setting last time notification were checked");

    try {
      final playerBox = await getBox(AppHiveBox.player.name);
      await playerBox.put(AppHiveConstants.lastIndex, lastIndex);
      await playerBox.put(AppHiveConstants.lastPos, lastPos);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

}
