import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Recovers a corrupted Hive box by deleting the underlying files and reopening.
Future<Box> recoverHiveBox(String boxName) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  final String dirPath = dir.path;
  final File dbFile = File('$dirPath/$boxName.hive');
  final File lockFile = File('$dirPath/$boxName.lock');

  if (dbFile.existsSync()) await dbFile.delete();
  if (lockFile.existsSync()) await lockFile.delete();

  return await Hive.openBox(boxName);
}
