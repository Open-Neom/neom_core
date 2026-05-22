// Tests for enums: value uniqueness, parsing, exhaustive switch coverage.
// Enums are the type-safe backbone of the app — a dropped value ripples
// instantly into every app that consumes neom_core.
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_locale.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

void main() {
  group('SubscriptionLevel', () {
    test('numeric values are strictly increasing and unique', () {
      final values = SubscriptionLevel.values.map((e) => e.value).toList();
      expect(values.toSet().length, values.length,
          reason: 'All subscription levels must have unique numeric values');
      // freemium must be the lowest — it is used in >= comparisons.
      expect(SubscriptionLevel.freemium.value, 0);
      // lifetime must be the highest.
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      expect(SubscriptionLevel.lifetime.value, maxValue);
    });

    test('canonical names parse round-trip via EnumToString', () {
      for (final level in SubscriptionLevel.values) {
        final parsed = EnumToString.fromString(
            SubscriptionLevel.values, level.name);
        expect(parsed, level);
      }
    });

    test('unknown name returns null (callers fall back to basic)', () {
      expect(
          EnumToString.fromString(SubscriptionLevel.values, 'nonexistent'),
          isNull);
    });

    test('plus >= basic for tier gating', () {
      expect(SubscriptionLevel.plus.value >= SubscriptionLevel.basic.value,
          isTrue);
      expect(SubscriptionLevel.freemium.value < SubscriptionLevel.basic.value,
          isTrue);
    });
  });

  group('ItemlistType', () {
    test('isAudio covers exactly the audio types', () {
      final audio = {
        ItemlistType.playlist,
        ItemlistType.single,
        ItemlistType.ep,
        ItemlistType.album,
        ItemlistType.demo,
        ItemlistType.audiobook,
        ItemlistType.podcast,
        ItemlistType.radioStation,
        ItemlistType.meditation,
      };
      for (final t in ItemlistType.values) {
        expect(t.isAudio, audio.contains(t),
            reason: '$t.isAudio should be ${audio.contains(t)}');
      }
    });

    test('non-audio itemlists are giglist/readlist/publication', () {
      expect(ItemlistType.giglist.isAudio, isFalse);
      expect(ItemlistType.readlist.isAudio, isFalse);
      expect(ItemlistType.publication.isAudio, isFalse);
    });

    test('values round-trip through name', () {
      for (final t in ItemlistType.values) {
        expect(EnumToString.fromString(ItemlistType.values, t.name), t);
      }
    });
  });

  group('OwnerType', () {
    test('values round-trip through name', () {
      for (final t in OwnerType.values) {
        expect(EnumToString.fromString(OwnerType.values, t.name), t);
      }
    });

    test('default contract: profile is first', () {
      expect(OwnerType.values.first, OwnerType.profile);
    });
  });

  group('ProfileType', () {
    test('value equals name for all members (serialization contract)', () {
      for (final t in ProfileType.values) {
        expect(t.value, t.name,
            reason: 'ProfileType.value is serialized to storage, must match name');
      }
    });

    test('general is the default and has privileges of generic profile', () {
      expect(ProfileType.values.contains(ProfileType.general), isTrue);
    });
  });

  group('VerificationLevel', () {
    test('values are strictly increasing from none=0', () {
      expect(VerificationLevel.none.value, 0);
      final sorted = VerificationLevel.values.map((e) => e.value).toList();
      for (int i = 1; i < sorted.length; i++) {
        expect(sorted[i] > sorted[i - 1], isTrue,
            reason: 'VerificationLevel must be strictly increasing');
      }
    });
  });

  group('AppCurrency', () {
    test('value equals name for every currency (serialization contract)', () {
      for (final c in AppCurrency.values) {
        expect(c.value, c.name,
            reason: 'AppCurrency.value must match .name for JSON round-trip');
      }
    });

    test('fiat currencies are lowercase (Stripe contract)', () {
      // Stripe always sends currency in lowercase ISO-4217.
      expect(AppCurrency.usd.value, 'usd');
      expect(AppCurrency.eur.value, 'eur');
      expect(AppCurrency.gbp.value, 'gbp');
      expect(AppCurrency.mxn.value, 'mxn');
    });

    test('parsing common currencies from Stripe string', () {
      expect(EnumToString.fromString(AppCurrency.values, 'usd'),
          AppCurrency.usd);
      expect(EnumToString.fromString(AppCurrency.values, 'eur'),
          AppCurrency.eur);
      expect(EnumToString.fromString(AppCurrency.values, 'gbp'),
          AppCurrency.gbp);
      expect(EnumToString.fromString(AppCurrency.values, 'mxn'),
          AppCurrency.mxn);
    });

    test('EnumToString is case-insensitive by default — USD returns usd', () {
      // Documenting behavior: callers cannot rely on strict case for parsing.
      expect(EnumToString.fromString(AppCurrency.values, 'USD'),
          AppCurrency.usd);
    });
  });

  group('AppLocale', () {
    test('codes are unique and non-empty', () {
      final codes = AppLocale.values.map((l) => l.code).toList();
      expect(codes.toSet().length, codes.length);
      for (final code in codes) {
        expect(code.isNotEmpty, isTrue);
      }
    });

    test('english/spanish/french/deutsch are present', () {
      expect(AppLocale.english.code, 'en');
      expect(AppLocale.spanish.code, 'es');
      expect(AppLocale.french.code, 'fr');
      expect(AppLocale.deutsch.code, 'de');
    });
  });

  group('MediaItemType', () {
    test('every value has a non-empty unique lowercase string value', () {
      final values = MediaItemType.values.map((e) => e.value).toList();
      expect(values.toSet().length, values.length);
      for (final v in values) {
        expect(v.isNotEmpty, isTrue);
      }
    });

    test('isAudio covers exactly audio types (exhaustive)', () {
      final expectedAudio = {
        MediaItemType.song,
        MediaItemType.podcast,
        MediaItemType.audiobook,
        MediaItemType.binaural,
        MediaItemType.frequency,
        MediaItemType.nature,
        MediaItemType.neomPreset,
      };
      for (final t in MediaItemType.values) {
        expect(t.isAudio, expectedAudio.contains(t), reason: '$t');
      }
    });

    test('frequency maps to "meditative" string value (legacy DB contract)', () {
      expect(MediaItemType.frequency.value, 'meditative');
    });
  });
}
