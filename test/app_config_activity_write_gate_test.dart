import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _FakeUserService extends Fake implements UserService {
  @override
  final AppUser user;

  _FakeUserService(this.user);
}

class _FakeFirebaseUser extends Fake implements fba.User {}

class _FakeLoginService extends Fake implements LoginService {
  _FakeLoginService({this.status = AuthStatus.loggedIn, this.user});

  final AuthStatus status;
  final fba.User? user;

  @override
  AuthStatus getAuthStatus() => status;

  @override
  fba.User? get fbaUser => user;
}

void main() {
  final config = AppConfig.instance;

  setUp(() {
    Sint.reset();
    config.isGuestMode = true;
  });

  tearDown(() {
    Sint.reset();
    config.isGuestMode = true;
  });

  test('guest clients cannot persist user activity', () {
    Sint.put<UserService>(_FakeUserService(AppUser(id: 'registered-user')));

    expect(config.canPersistUserActivity, isFalse);
  });

  test('dismissed guest mode is not enough without a loaded account', () {
    config.isGuestMode = false;

    expect(config.canPersistUserActivity, isFalse);
  });

  test('loaded registered users can persist user activity', () {
    config.isGuestMode = false;
    Sint.put<LoginService>(_FakeLoginService(user: _FakeFirebaseUser()));
    Sint.put<UserService>(_FakeUserService(AppUser(id: 'registered-user')));

    expect(config.canPersistUserActivity, isTrue);
  });

  test('a stale user id after Firebase logout cannot persist activity', () {
    config.isGuestMode = false;
    Sint.put<LoginService>(
      _FakeLoginService(status: AuthStatus.notLoggedIn),
    );
    Sint.put<UserService>(_FakeUserService(AppUser(id: 'stale-user')));

    expect(config.canPersistUserActivity, isFalse);
  });
}
