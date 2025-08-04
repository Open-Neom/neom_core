import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/enums/app_locale.dart';
import '../model/app_release_item.dart';
// Necesario para Box

/// Interfaz para el servicio de gestión de caché local (Hive).
abstract class AppHiveService {
  // Métodos que exponen funcionalidades de caché
  Future<void> init(); // Para inicializar el servicio

  // Métodos para obtener/escribir información de perfil
  Future<void> fetchProfileInfo();
  Future<void> writeProfileInfo();

  // Métodos para obtener/escribir datos cacheados generales
  Future<void> fetchCachedData();
  Future<void> fetchSettingsData();
  Future<void> setSearchQueries(List searchQueries);
  Future<void> addQuery(String query);
  Future<void> saveMainItem(AppReleaseItem item);
  Future<File?> getCachedPdf(String id);
  Future<void> cachePdf(String id, File file);

  // Métodos para gestionar la localización
  Future<void> updateLocale(AppLocale appLocale);
  void setLocale(AppLocale appLocale);

  // Métodos para gestionar el estado de la aplicación
  Future<void> setFirstTime(bool fTime);
  Future<void> setLastNotificationCheckDate(int lastNotificationCheckDate);
  Future<void> setLastIndexPos({required int? lastIndex, required int lastPos});

  // Métodos para gestionar cajas (si se exponen)
  Future<Box> openHiveBox(String boxName, {bool limit = false});
  Future<Box> getBox(String boxName, {bool limit = false});
  Future<void> clearBox(String boxName);

  String get releaseLastUpdate;
  set releaseLastUpdate(String update);

  // Getters para datos cacheados (si son parte del contrato)
  // bool get firstTime;
  // int get lastNotificationCheckDate;
  // List get searchedList;
  // List get searchQueries;
  // Map<String, AppReleaseItem> get mainItems;
  // Map<String, AppReleaseItem> get secondaryItems;
  // Map<String, Itemlist> get releaseItemlists;
  // String get releaseLastUpdate;
  // String get directoryLastUpdate;
}
