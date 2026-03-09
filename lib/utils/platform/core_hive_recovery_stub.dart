import 'package:hive_flutter/hive_flutter.dart';

/// On web, Hive uses IndexedDB. No file recovery needed — just reopen.
Future<Box> recoverHiveBox(String boxName) async {
  return await Hive.openBox(boxName);
}
