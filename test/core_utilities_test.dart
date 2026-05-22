// Tests for CoreUtilities — the main static helper used everywhere.
// Targets: getItemState, getMediaItemType, getCurrencySymbol, isWithinFirstMonth.
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/domain/model/app_release_item.dart';

void main() {
  group('CoreUtilities.getItemState', () {
    test('numeric mapping is exhaustive 0..5', () {
      expect(CoreUtilities.getItemState(0), AppItemState.noState);
      expect(CoreUtilities.getItemState(1), AppItemState.heardIt);
      expect(CoreUtilities.getItemState(2), AppItemState.learningIt);
      expect(CoreUtilities.getItemState(3), AppItemState.needToPractice);
      expect(CoreUtilities.getItemState(4), AppItemState.readyToPlay);
      expect(CoreUtilities.getItemState(5), AppItemState.knowByHeart);
    });

    test('out-of-range returns noState', () {
      expect(CoreUtilities.getItemState(-1), AppItemState.noState);
      expect(CoreUtilities.getItemState(99), AppItemState.noState);
    });
  });

  group('CoreUtilities.getCurrencySymbol', () {
    test('USD/MXN/AppCoin all use \$', () {
      expect(CoreUtilities.getCurrencySymbol(AppCurrency.usd), '\$');
      expect(CoreUtilities.getCurrencySymbol(AppCurrency.mxn), '\$');
      expect(CoreUtilities.getCurrencySymbol(AppCurrency.appCoin), '\$');
    });

    test('EUR uses €', () {
      expect(CoreUtilities.getCurrencySymbol(AppCurrency.eur), '€');
    });

    test('GBP uses £', () {
      expect(CoreUtilities.getCurrencySymbol(AppCurrency.gbp), '£');
    });

    test('switch is exhaustive — all enum values produce some symbol', () {
      for (final c in AppCurrency.values) {
        expect(CoreUtilities.getCurrencySymbol(c).isNotEmpty, isTrue);
      }
    });
  });

  group('CoreUtilities.isWithinFirstMonth', () {
    test('just-created timestamp is within first month', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(CoreUtilities.isWithinFirstMonth(now), isTrue);
    });

    test('timestamp 60 days ago is NOT within first month', () {
      final twoMonthsAgo = DateTime.now()
          .subtract(const Duration(days: 60))
          .millisecondsSinceEpoch;
      expect(CoreUtilities.isWithinFirstMonth(twoMonthsAgo), isFalse);
    });

    test('timestamp 5 days ago is within first month', () {
      final fiveDaysAgo = DateTime.now()
          .subtract(const Duration(days: 5))
          .millisecondsSinceEpoch;
      expect(CoreUtilities.isWithinFirstMonth(fiveDaysAgo), isTrue);
    });
  });

  group('CoreUtilities.getMediaItemType (release type → media type)', () {
    // BUG history: episode/chapter cases originally lacked terminating
    // statements before default. Dart 3 silently runs the case body without
    // an implicit fall-through (terminator inference) so behavior depended
    // on declaration order. These tests pin the contract.

    test('single → song', () {
      final item =
          AppReleaseItem(type: ReleaseType.single, previewUrl: 'a.mp3');
      expect(CoreUtilities.getMediaItemType(item), MediaItemType.song);
    });

    test('single ending in .pdf → pdf', () {
      final item =
          AppReleaseItem(type: ReleaseType.single, previewUrl: 'doc.PDF');
      expect(CoreUtilities.getMediaItemType(item), MediaItemType.pdf);
    });

    test('episode → podcast', () {
      final item =
          AppReleaseItem(type: ReleaseType.episode, previewUrl: 'p.mp3');
      expect(CoreUtilities.getMediaItemType(item), MediaItemType.podcast);
    });

    test('chapter → audiobook', () {
      final item =
          AppReleaseItem(type: ReleaseType.chapter, previewUrl: 'c.mp3');
      expect(CoreUtilities.getMediaItemType(item), MediaItemType.audiobook);
    });

    test('ep / album / demo → song fallback', () {
      for (final t in [
        ReleaseType.ep,
        ReleaseType.album,
        ReleaseType.demo,
      ]) {
        final item = AppReleaseItem(type: t, previewUrl: 'a.mp3');
        expect(CoreUtilities.getMediaItemType(item), MediaItemType.song);
      }
    });
  });

  group('AppReleaseItem.displayDuration', () {
    test('zero duration → empty', () {
      final i = AppReleaseItem(duration: 0);
      expect(i.displayDuration, '');
    });

    test('seconds-only formats m:ss with zero pad', () {
      final i = AppReleaseItem(duration: 65); // 1m 5s
      expect(i.displayDuration, '1:05');
    });

    test('minutes-only', () {
      final i = AppReleaseItem(duration: 600); // 10m 0s
      expect(i.displayDuration, '10:00');
    });

    test('hours add the h prefix', () {
      final i = AppReleaseItem(duration: 3661); // 1h 1m 1s
      expect(i.displayDuration, '1h 01m');
    });
  });
}
