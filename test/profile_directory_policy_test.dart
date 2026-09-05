import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/profile_directory_policy.dart';

void main() {
  group('ProfileDirectoryPolicy', () {
    test('public readers only list directory-visible profiles', () {
      expect(
        ProfileDirectoryPolicy.canList(
          AppProfile(directoryVisible: true),
          isPublicReader: true,
        ),
        isTrue,
      );
      expect(
        ProfileDirectoryPolicy.canList(
          AppProfile(directoryVisible: false),
          isPublicReader: true,
        ),
        isFalse,
      );
    });

    test('authenticated readers are not constrained by directory listing', () {
      expect(
        ProfileDirectoryPolicy.canList(
          AppProfile(directoryVisible: false),
          isPublicReader: false,
        ),
        isTrue,
      );
    });

    test('public projection always removes email', () {
      final profile = AppProfile()..email = 'private@example.com';

      ProfileDirectoryPolicy.applyFieldRedactions(
        profile,
        isPublicReader: true,
      );

      expect(profile.email, isEmpty);
    });

    test('phone follows showPhone for every directory reader', () {
      final hiddenPhone = AppProfile(
        phoneNumber: '+52 555 0100',
        showPhone: false,
      );
      final shownPhone = AppProfile(
        phoneNumber: '+52 555 0101',
        showPhone: true,
      );

      ProfileDirectoryPolicy.applyFieldRedactions(
        hiddenPhone,
        isPublicReader: false,
      );
      ProfileDirectoryPolicy.applyFieldRedactions(
        shownPhone,
        isPublicReader: true,
      );

      expect(hiddenPhone.phoneNumber, isEmpty);
      expect(shownPhone.phoneNumber, '+52 555 0101');
    });

    test('public projection keeps identity but removes private state', () {
      final source = AppProfile(
        id: 'profile-1',
        name: 'Visible Artist',
        aboutMe: 'Public bio',
        photoUrl: 'https://example.test/avatar.jpg',
        address: 'Private address',
        phoneNumber: '+52 555 0102',
        showPhone: true,
        itemmates: ['profile-5'],
        eventmates: ['profile-6'],
        posts: ['private-post-id'],
        events: ['private-event-id'],
        followers: ['profile-2'],
        following: ['profile-3'],
        unfollowing: ['profile-7'],
        blockTo: ['profile-4'],
        blockedBy: ['profile-8'],
        reports: ['report-1'],
        requests: ['request-1'],
        sentRequests: ['request-2'],
        invitationRequests: ['request-3'],
        favoriteItems: ['favorite-1'],
        savedItemlistIds: ['saved-1'],
        watchingEvents: ['event-2'],
        goingEvents: ['event-3'],
        playingEvents: ['event-4'],
        itemlists: {'private-list': Itemlist(id: 'private-list')},
        giglists: {'private-gig': Itemlist(id: 'private-gig')},
      )..email = 'private@example.com';

      final projected = ProfileDirectoryPolicy.publicProjection(source);

      expect(projected.id, source.id);
      expect(projected.name, source.name);
      expect(projected.aboutMe, source.aboutMe);
      expect(projected.photoUrl, source.photoUrl);
      expect(projected.phoneNumber, source.phoneNumber);
      expect(projected.email, isEmpty);
      expect(projected.address, isEmpty);
      expect(projected.posts, isEmpty);
      expect(projected.events, isEmpty);
      expect(projected.itemmates, isEmpty);
      expect(projected.eventmates, isEmpty);
      expect(projected.followers, isEmpty);
      expect(projected.following, isEmpty);
      expect(projected.unfollowing, isEmpty);
      expect(projected.blockTo, isEmpty);
      expect(projected.blockedBy, isEmpty);
      expect(projected.reports, isEmpty);
      expect(projected.requests, isEmpty);
      expect(projected.sentRequests, isEmpty);
      expect(projected.invitationRequests, isEmpty);
      expect(projected.favoriteItems, isEmpty);
      expect(projected.savedItemlistIds, isEmpty);
      expect(projected.watchingEvents, isEmpty);
      expect(projected.goingEvents, isEmpty);
      expect(projected.playingEvents, isEmpty);
      expect(projected.itemlists, isEmpty);
      expect(projected.giglists, isEmpty);

      expect(source.email, 'private@example.com');
      expect(source.address, 'Private address');
      expect(source.posts, ['private-post-id']);
    });

    test('public projection hides phone when showPhone is false', () {
      final source = AppProfile(phoneNumber: '+52 555 0103', showPhone: false);

      final projected = ProfileDirectoryPolicy.publicProjection(source);

      expect(projected.phoneNumber, isEmpty);
    });

    test('public projection returns no identity for hidden profiles', () {
      final source = AppProfile(
        id: 'hidden-profile',
        name: 'Hidden',
        directoryVisible: false,
      );

      final projected = ProfileDirectoryPolicy.publicProjection(source);

      expect(projected.id, isEmpty);
      expect(projected.name, isEmpty);
    });
  });
}
