import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/model/app_release_item.dart';
import '../../domain/model/item_list.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_hive_constants.dart';
import '../../utils/enums/app_hive_box.dart';


class AppHiveController extends GetxController {

  //SEARCH Cache
  List searchedList = [];
  List searchQueries = [];

  //RELEASES CACHE
  Map<String, AppReleaseItem> mainItems = {};
  Map<String, AppReleaseItem> secondaryItems = {};
  Map<String, Itemlist> releaseItemlists = {};
  String releaseLastUpdate = '';

  @override
  Future<void> onInit() async {
    super.onInit();
    AppUtilities.logger.t('AppHive Controller');

    try {
      await Hive.initFlutter();
      for (AppHiveBox box in AppHiveBox.values) {
        await openHiveBox(box.name, limit: box.limit,
        );
      }

      fetchCachedData();
      fetchSettingsData();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Box? getBox(String boxName) {
    return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
  }

  Future<void> openHiveBox(String boxName, {bool limit = false}) async {
    AppUtilities.logger.t('openHiveBox');
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
  }

  void fetchCachedData() {
    AppUtilities.logger.d('fetchCachedData');
    // Usa un cast seguro (as Map<dynamic, dynamic>?) y el operador ?.
    final rawMainItems = Hive.box(AppHiveBox.releases.name).get(AppHiveConstants.mainItems) as Map<dynamic, dynamic>?;
    mainItems = rawMainItems?.map((key, value) => MapEntry(key, AppReleaseItem.fromJSON(value))) ?? {};

    final rawSecondaryItems = Hive.box(AppHiveBox.releases.name).get(AppHiveConstants.secondaryItems) as Map<dynamic, dynamic>?;
    secondaryItems = rawSecondaryItems?.map((key, value) => MapEntry(key, AppReleaseItem.fromJSON(value))) ?? {};


// De igual forma para releaseItemlists:
    final rawReleaseItemLists = Hive.box(AppHiveBox.releases.name).get(AppHiveConstants.releaseItemLists) as Map<dynamic, dynamic>?;
    releaseItemlists = rawReleaseItemLists?.map((key, value) => MapEntry(key, Itemlist.fromJSON(value))) ?? {};

    final rawReleaseLastUpdate = Hive.box(AppHiveBox.releases.name).get(AppHiveConstants.lastUpdate) as String?;
    releaseLastUpdate = rawReleaseLastUpdate ?? '';
  }

  void fetchSettingsData() {
    AppUtilities.logger.d('fetchSettingsData');
    searchQueries = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.searchQueries, defaultValue: []) as List;
  }

  Future<void> setSearchQueries(List searchQueries) async {
    AppUtilities.logger.d('setSearchQueries');
    await Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.searchQueries, searchQueries);
  }

  Future<void> addQuery(String query) async {
    query = query.trim();
    List searchQueries = Hive.box(AppHiveBox.settings.name).get(AppHiveConstants.search, defaultValue: [],) as List;
    final idx = searchQueries.indexOf(query);
    if (idx != -1) searchQueries.removeAt(idx);
    searchQueries.insert(0, query);
    if (searchQueries.length > 10) searchQueries = searchQueries.sublist(0, 10);
    Hive.box(AppHiveBox.settings.name).put(AppHiveConstants.search, searchQueries);
  }

  Future<void> saveMainItem(AppReleaseItem item) async {
    mainItems[item.id] = item;
    await Hive.box(AppHiveBox.releases.name).put(AppHiveConstants.mainItems, mainItems);
  }

  File? getCachedPdf(String id) {
    final box = getBox(AppHiveBox.pdfCache.name);
    if (box != null) {
      final String? cachedPath = box.get(id);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return File(cachedPath);
      }
    }
    return null;
  }

  /// Guarda la ruta del archivo PDF en el caché usando la URL como key
  Future<void> cachePdf(String id, File file) async {
    final box = getBox(AppHiveBox.pdfCache.name);
    if (box != null) {
      await box.put(id, file.path);
    }
  }

}
