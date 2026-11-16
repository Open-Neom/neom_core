import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/implementations/app_hive_controller.dart';

/// Recovers a corrupted Hive box by deleting the underlying regular files and reopening.
Future<Box> recoverHiveBox(String boxName) async {
  if (!AppHiveController.isSafeHiveBoxName(boxName)) {
    throw ArgumentError.value(boxName, 'boxName', 'Unsafe Hive box name');
  }
  final Directory dir = await getApplicationDocumentsDirectory();
  final String dirPath = dir.path;
  if (!AppHiveController.hasSymlinkAncestor('$dirPath/$boxName.hive')) {
    for (final ext in const <String>['.hive', '.lock']) {
      final targetPath = '$dirPath/$boxName$ext';
      try {
        if (FileSystemEntity.typeSync(targetPath, followLinks: false) ==
            FileSystemEntityType.file) {
          await File(targetPath).delete();
        }
      } catch (_) {}
    }
  }

  return await Hive.openBox(boxName);
}
