import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// On web, Hive uses IndexedDB. No file recovery needed — just reopen.
Future<Box> recoverHiveBox(String boxName) async {
  return await Hive.openBox(boxName);
}
