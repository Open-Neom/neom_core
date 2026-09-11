import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/utils/enums/user_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserRole — jerarquía de permisos', () {
    test('isSupportOrAbove solo es verdadero para support y superiores', () {
      expect(UserRole.subscriber.isSupportOrAbove, isFalse);
      expect(UserRole.editor.isSupportOrAbove, isFalse);
      expect(UserRole.support.isSupportOrAbove, isTrue);
      expect(UserRole.erp.isSupportOrAbove, isTrue);
      expect(UserRole.pos.isSupportOrAbove, isTrue);
      expect(UserRole.developer.isSupportOrAbove, isTrue);
      expect(UserRole.admin.isSupportOrAbove, isTrue);
      expect(UserRole.superAdmin.isSupportOrAbove, isTrue);
    });

    test('isAdminOrAbove solo es verdadero para admin y superAdmin', () {
      expect(UserRole.subscriber.isAdminOrAbove, isFalse);
      expect(UserRole.editor.isAdminOrAbove, isFalse);
      expect(UserRole.support.isAdminOrAbove, isFalse);
      expect(UserRole.erp.isAdminOrAbove, isFalse);
      expect(UserRole.pos.isAdminOrAbove, isFalse);
      expect(UserRole.developer.isAdminOrAbove, isFalse);
      expect(UserRole.admin.isAdminOrAbove, isTrue);
      expect(UserRole.superAdmin.isAdminOrAbove, isTrue);
    });
  });

  group('UserController — sincronización de profile.posts', () {
    late UserController userController;

    setUp(() {
      final firestore = FakeFirebaseFirestore();
      final repository = UserFirestore(firestore: firestore);
      userController = UserController(userFirestore: repository);
      final testProfile = AppProfile(id: 'prof_1');
      testProfile.posts = ['post_1', 'post_2'];
      userController.profile = testProfile;
      userController.user = AppUser(
        id: 'user_1',
        profiles: [testProfile],
      );
    });

    tearDown(() {
      userController.onClose();
    });

    test('addPostToProfile agrega el ID al perfil activo y lista de perfiles', () {
      userController.addPostToProfile('post_3');

      expect(userController.profile.posts, contains('post_3'));
      expect(userController.profile.posts!.length, 3);
      expect(userController.user.profiles.first.posts, contains('post_3'));
    });

    test('addPostToProfile no duplica IDs si ya existe', () {
      userController.addPostToProfile('post_1');

      expect(userController.profile.posts!.where((id) => id == 'post_1').length, 1);
    });

    test('removePostFromProfile elimina el ID del perfil activo y emite en stream', () async {
      final emittedPosts = <String>[];
      final sub = userController.postRemovedStream.listen(emittedPosts.add);

      userController.removePostFromProfile('post_1');

      expect(userController.profile.posts, isNot(contains('post_1')));
      expect(userController.profile.posts, contains('post_2'));
      expect(userController.profile.posts!.length, 1);
      expect(userController.user.profiles.first.posts, isNot(contains('post_1')));

      await Future.delayed(Duration.zero);
      expect(emittedPosts, contains('post_1'));

      await sub.cancel();
    });

    test('removePostFromProfile con ownerId distinto no modifica perfil local', () async {
      userController.removePostFromProfile('post_2', ownerId: 'other_prof');

      expect(userController.profile.posts, contains('post_2'));
    });
  });
}
