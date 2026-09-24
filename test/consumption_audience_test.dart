import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/implementations/release_ownership_resolver.dart';
import 'package:neom_core/domain/model/casete/casete_session.dart';
import 'package:neom_core/domain/model/nupale/nupale_session.dart';
import 'package:neom_core/utils/consumption_audience_policy.dart';
import 'package:neom_core/utils/enums/consumption_audience.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('who funds royalties', () {
    ConsumptionAudience classify({bool author = false, SubscriptionLevel? level}) =>
        ConsumptionAudiencePolicy.classify(isAuthor: author, level: level);

    test('a paying member who owns no release is the only funding audience', () {
      for (final level in SubscriptionLevel.values.where((l) => l.value >= SubscriptionLevel.basic.value)) {
        expect(classify(level: level), ConsumptionAudience.member, reason: level.name);
      }
    });

    test('an author on a paid plan is still an author', () {
      // Listening to anyone's work would lower the value per second — their
      // own earnings included.
      expect(classify(author: true, level: SubscriptionLevel.premium), ConsumptionAudience.author);
      expect(classify(author: true, level: SubscriptionLevel.freemium), ConsumptionAudience.author);
    });

    test('no paid tier is analytics only', () {
      expect(classify(level: SubscriptionLevel.freemium), ConsumptionAudience.freeTier);
      expect(classify(level: null), ConsumptionAudience.freeTier);
      expect(classify(level: SubscriptionLevel.freeMonth), ConsumptionAudience.freeTier,
          reason: 'A free month of a paid plan brings no revenue into the pool.');
    });
  });

  group('release ownership', () {
    late DateTime now;
    late int profileLookups;
    late int emailLookups;
    late bool ownsByEmail;

    ReleaseOwnershipResolver resolver() => ReleaseOwnershipResolver(
          ownsByProfileId: (id) async {
            profileLookups++;
            return id == 'author-profile';
          },
          ownsByEmail: (email) async {
            emailLookups++;
            return ownsByEmail;
          },
          now: () => now,
        );

    setUp(() {
      ReleaseOwnershipResolver.clearCache();
      now = DateTime(2026, 9, 23);
      profileLookups = 0;
      emailLookups = 0;
      ownsByEmail = false;
    });

    test('a release under any of the profiles makes an author', () async {
      expect(await resolver().ownsAnyReleaseItem(
          email: 'a@x.com', profileIds: ['listener-profile', 'author-profile']), isTrue);
    });

    test('a release found by email makes an author', () async {
      ownsByEmail = true;
      expect(await resolver().ownsAnyReleaseItem(email: 'a@x.com', profileIds: ['p']), isTrue);
    });

    test('old releaseItemIds still count, without a query', () async {
      expect(await resolver().ownsAnyReleaseItem(
          email: 'a@x.com', legacyReleaseItemIds: ['old-release']), isTrue);
      expect(profileLookups + emailLookups, 0);
    });

    test('the answer is cached, then asked again after the TTL', () async {
      final r = resolver();
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com', profileIds: ['p']), isFalse);
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com', profileIds: ['p']), isFalse);
      expect(emailLookups, 1, reason: 'Every listening session must not cost a query.');

      ownsByEmail = true; // the listener published something
      now = now.add(ReleaseOwnershipResolver.cacheTtl);
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com', profileIds: ['p']), isTrue);
    });

    test('invalidate picks up a new release at once', () async {
      final r = resolver();
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com'), isFalse);
      ownsByEmail = true;
      ReleaseOwnershipResolver.invalidate('a@x.com');
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com'), isTrue);
    });

    test('a failed lookup is not cached as "not an author"', () async {
      var fail = true;
      final r = ReleaseOwnershipResolver(
        ownsByProfileId: (_) async => false,
        ownsByEmail: (_) async {
          if (fail) throw StateError('offline');
          return true;
        },
        now: () => now,
      );
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com'), isFalse);
      fail = false;
      expect(await r.ownsAnyReleaseItem(email: 'a@x.com'), isTrue);
    });
  });

  group('audience on stored sessions', () {
    test('casete and nupale sessions keep their audience', () {
      expect(CaseteSession.fromJSON(CaseteSession(audience: ConsumptionAudience.author).toJSON()).audience,
          ConsumptionAudience.author);
      expect(NupaleSession.fromJSON(NupaleSession(audience: ConsumptionAudience.freeTier).toJSON()).audience,
          ConsumptionAudience.freeTier);
    });

    test('a session written before the field existed reads as member', () {
      final legacy = CaseteSession().toJSON()..remove('audience');
      expect(CaseteSession.fromJSON(legacy).audience, ConsumptionAudience.member);
    });
  });
}
