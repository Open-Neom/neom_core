import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/use_cases/app_hive_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/app_hive_box.dart';
import '../../utils/enums/app_locale.dart';

class AppHiveController implements AppHiveService {

  static final AppHiveController _instance = AppHiveController._internal();

  factory AppHiveController() {
    _instance.init();
    return _instance;
  }

  AppHiveController._internal();

  bool _isInitialized = false;

  final userServiceImpl = Sint.find<UserService>();
  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  //SEARCH Cache
  List searchedList = [];
  List searchQueries = [];

  //RELEASES CACHE
  Map<String, AppReleaseItem> mainItems = {};
  Map<String, AppReleaseItem> secondaryItems = {};
  Map<String, Itemlist> releaseItemlists = {};
  String _releaseLastUpdate = '';
  String directoryLastUpdate = '';

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    AppConfig.logger.t('AppHive Controller Initialization');

    try {
      // await Hive.initFlutter();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }



  @override
  Future<Box> getBox(String boxName, {bool limit = false}) async {
    return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await openHiveBox(boxName, limit: limit);
  }

  @override
  Future<Box> openHiveBox(String boxName, {bool limit = false}) async {
    AppConfig.logger.t('openHiveBox $boxName');
    final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
      AppConfig.logger.e('Failed to open $boxName Box');
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
      AppConfig.logger.w("Box $boxName would be cleared as it exceeded the limit");
      box.clear();
    }

    return box;
  }

  @override
  Future<void> clearBox(String boxName) async {
    Box box = await getBox(boxName);
    box.clear();
  }

  @override
  Future<void> fetchProfileInfo() async {
    AppConfig.logger.d('fetchProfileInfo');

    final profileBox = await getBox(AppHiveBox.profile.name);
    userServiceImpl.user.id = profileBox.get(AppHiveConstants.userId, defaultValue: '');
    userServiceImpl.user.name = profileBox.get(AppHiveConstants.username, defaultValue: '');
    userServiceImpl.profile.id = profileBox.get(AppHiveConstants.profileId, defaultValue: '');
    userServiceImpl.profile.aboutMe = profileBox.get(AppHiveConstants.aboutMe, defaultValue: '');
    userServiceImpl.profile.photoUrl = profileBox.get(AppHiveConstants.photoUrl, defaultValue: '');
    firstTime = profileBox.get(AppHiveConstants.firstTime, defaultValue: false);
    lastNotificationCheckDate = profileBox.get(AppHiveConstants.lastNotificationCheckDate, defaultValue: 0);

    await userServiceImpl.getProfiles();

    final savedLocale = profileBox.get(AppHiveConstants.appLocale, defaultValue: 'spanish');
    if(savedLocale.isNotEmpty) {
      setLocale(EnumToString.fromString(AppLocale.values, savedLocale)!);
    } else {
      AppLocale appLocale = AppLocale.spanish;

      switch(Sint.locale?.languageCode ?? "") {
        case CoreConstants.en:
          appLocale = AppLocale.english;
          break;
        case CoreConstants.es:
          appLocale = AppLocale.spanish;
          break;
        case CoreConstants.fr:
          appLocale = AppLocale.french;
          break;
        case CoreConstants.de:
          appLocale = AppLocale.deutsch;
          break;
        default:
          break;
      }

      setLocale(appLocale);
      updateLocale(appLocale);
    }

  }

  @override
  Future<void> writeProfileInfo({bool overwrite = false}) async {
    AppConfig.logger.d('writeProfileInfo');
    try {
      final box = await getBox(AppHiveBox.profile.name);

      String userId = box.get(AppHiveConstants.userId, defaultValue: '');

      if(userId.isEmpty || overwrite) {
        await box.put(AppHiveConstants.userId, userServiceImpl.user.id);
        await box.put(AppHiveConstants.username, userServiceImpl.user.name);
        await box.put(AppHiveConstants.profileId, userServiceImpl.profile.id);
        await box.put(AppHiveConstants.photoUrl, userServiceImpl.user.photoUrl);
        await box.put(AppHiveConstants.firstTime, false);
      }
    } catch (e) {
      AppConfig.logger.e('Error writing profile info: $e');
    }

  }

  @override
  Future<void> fetchCachedData() async {
    AppConfig.logger.d('fetchCachedData');
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

    final rawReleaseItemLists = releasesBox.get(AppHiveConstants.releaseItemLists) as Map<dynamic, dynamic>?;
    releaseItemlists = rawReleaseItemLists?.map((key, value) => MapEntry(key, Itemlist.fromJSON(value))) ?? {};

    final rawReleaseLastUpdate = releasesBox.get(AppHiveConstants.lastUpdate) as String?;
    releaseLastUpdate = rawReleaseLastUpdate ?? '';


    final directoryBox = await getBox(AppHiveBox.directory.name);
    final rawDirectoryLastUpdate = directoryBox.get(AppHiveConstants.lastUpdate) as String?;
    directoryLastUpdate = rawDirectoryLastUpdate ?? '';

  }

  Map<String, AppReleaseItem> _mapToReleaseItem(Map<dynamic, dynamic> rawItems) {
    return rawItems.map((key, value) => MapEntry(key.toString(), AppReleaseItem.fromJSON(value)));
  }

  @override
  Future<void> fetchSettingsData() async {
    AppConfig.logger.d('fetchSettingsData');
    final settingsBox = await getBox(AppHiveBox.settings.name);
    searchQueries = settingsBox.get(AppHiveConstants.searchQueries, defaultValue: []) as List;
  }

  @override
  Future<void> setSearchQueries(List searchQueries) async {
    AppConfig.logger.d('setSearchQueries');
    final settingsBox = await getBox(AppHiveBox.settings.name);
    await settingsBox.put(AppHiveConstants.searchQueries, searchQueries);
  }

  @override
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
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> saveMainItem(AppReleaseItem item) async {
    mainItems[item.id] = item;
    final releaseBox = await getBox(AppHiveBox.releases.name);
    await releaseBox.put(AppHiveConstants.mainItems, mainItems);
    // await releaseBox.close();

  }

  @override
  Future<File?> getCachedPdf(String id) async {
    final pdfCacheBox = await getBox(AppHiveBox.pdfCache.name);
    final String? cachedPath = pdfCacheBox.get(id);
    if (cachedPath != null && File(cachedPath).existsSync()) {
      return File(cachedPath);
    }
      return null;
  }

  @override
  Future<void> cachePdf(String id, File file) async {
    final pdfCacheBox = await getBox(AppHiveBox.pdfCache.name);
    await pdfCacheBox.put(id, file.path);
  }

  @override
  Future<void> updateLocale(AppLocale appLocale) async {
    AppConfig.logger.d("Setting locale preference to ${appLocale.name}");

    try {
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.appLocale, appLocale.name);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void setLocale(AppLocale appLocale) {
    AppConfig.logger.d("Updating GetX locale to ${appLocale.name}");

    Locale locale = Sint.deviceLocale!;

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

    Sint.updateLocale(locale);
  }

  @override
  Future<void> setFirstTime(bool fTime) async {
    AppConfig.logger.t("Setting firsTime to $firstTime");

    try {
      firstTime = fTime;
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.firstTime, fTime);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> setLastNotificationCheckDate(int lastNotificationCheckDate) async {
    AppConfig.logger.d("Setting last time notification were checked");

    try {
      final profileBox = await getBox(AppHiveBox.profile.name);
      await profileBox.put(AppHiveConstants.lastNotificationCheckDate, lastNotificationCheckDate);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> setLastIndexPos({required int? lastIndex, required int lastPos}) async {
    AppConfig.logger.d("Setting last time notification were checked");

    try {
      final playerBox = await getBox(AppHiveBox.player.name);
      await playerBox.put(AppHiveConstants.lastIndex, lastIndex);
      await playerBox.put(AppHiveConstants.lastPos, lastPos);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  String get releaseLastUpdate => _releaseLastUpdate;

  @override
  set releaseLastUpdate(String update) {
    _releaseLastUpdate = update;
  }

}
