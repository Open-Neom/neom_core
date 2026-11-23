import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/implementations/local_user_service.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/user_role.dart';

void main() {
  group('LocalUserService', () {
    test('defaults to an empty guest identity with freemium subscriber role', () {
      final svc = LocalUserService();
      expect(svc.user.id, isEmpty);
      expect(svc.user.email, isEmpty);
      expect(svc.user.userRole, UserRole.subscriber);
      expect(svc.profile.id, isEmpty);
      expect(svc.subscriptionLevel, SubscriptionLevel.freemium);
      expect(svc.isNewUser, isFalse);
    });

    test('supports custom initial identity and local role/subscription updates', () {
      final svc = LocalUserService(
        initialUser: AppUser(
          id: 'pakal_local',
          name: 'Operador',
          email: 'local@pakal.mesh',
          userRole: UserRole.subscriber,
        ),
        initialProfile: AppProfile(id: 'pakal_prof', name: 'Operador'),
      );

      expect(svc.user.id, 'pakal_local');
      expect(svc.profile.name, 'Operador');

      svc.updateLocalUserRole(UserRole.admin);
      svc.updateLocalSubscriptionLevel(SubscriptionLevel.premium);
      expect(svc.user.userRole, UserRole.admin);
      expect(svc.subscriptionLevel, SubscriptionLevel.premium);
    });

    test('tracks local profile posts and emits postRemovedStream events', () async {
      final svc = LocalUserService(
        initialProfile: AppProfile(id: 'prof-1', name: 'Local'),
      );
      final removed = <String>[];
      final sub = svc.postRemovedStream.listen(removed.add);

      svc.addPostToProfile('post-1');
      svc.addPostToProfile('post-1');
      expect(svc.profile.posts, ['post-1']);

      svc.removePostFromProfile('post-1', ownerId: 'prof-1');
      await Future<void>.delayed(Duration.zero);

      expect(svc.profile.posts, isEmpty);
      expect(removed, ['post-1']);
      await sub.cancel();
    });

    test('removeAccount resets in-memory user, profile, and subscription state', () async {
      final svc = LocalUserService(
        initialUser: AppUser(id: 'u1', name: 'User', email: 'u@example.com'),
        initialProfile: AppProfile(id: 'p1', name: 'Profile'),
        initialSubscriptionLevel: SubscriptionLevel.premium,
      );

      await svc.removeAccount();
      expect(svc.user.id, isEmpty);
      expect(svc.profile.name, isEmpty);
      expect(svc.subscriptionLevel, SubscriptionLevel.freemium);
    });
  });
}
