import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('neom_core_catalog_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'unauthenticated restore bypasses catalogue without touching drafts',
    () async {
      final releasesBox = await Hive.openBox(AppHiveBox.releases.name);
      await releasesBox.put(AppHiveConstants.mainItems, {
        'legacy-release': {'id': 'legacy-release'},
      });
      await releasesBox.put(AppHiveConstants.lastUpdate, '2026-09-03');
      await releasesBox.put('release_draft_draft-1', {'id': 'draft-1'});
      await releasesBox.close();

      final controller = AppHiveController();
      await controller.fetchCachedDataForSession(
        hasAuthenticatedSession: false,
      );

      expect(Hive.isBoxOpen(AppHiveBox.releases.name), isFalse);
      expect(controller.mainItems, isEmpty);
      expect(controller.secondaryItems, isEmpty);
      expect(controller.releaseItemlists, isEmpty);
      expect(controller.releaseLastUpdate, isEmpty);

      final preservedBox = await Hive.openBox(AppHiveBox.releases.name);
      expect(preservedBox.get(AppHiveConstants.mainItems), isNotNull);
      expect(preservedBox.get(AppHiveConstants.lastUpdate), '2026-09-03');
      expect(preservedBox.get('release_draft_draft-1'), {'id': 'draft-1'});
      expect(controller.releaseLastUpdate, isEmpty);
    },
  );
}
