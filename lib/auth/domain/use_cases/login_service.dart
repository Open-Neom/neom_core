import 'package:flutter/material.dart';
import '../../../core/utils/enums/auth_status.dart';
import '../../utils/enums/login_method.dart';

abstract class LoginService {

  Future<void> getAppInfo();
  Future<void> handleAuthChanged(user);
  void setAuthStatus(AuthStatus status);
  void setIsLoading(bool loading);

  void handleLogin(LoginMethod loginMethod);

  Future<void> appleLogin();
  Future<void> googleLogin();
  Future<void> emailLogin();

  Future<void> signOut();
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey);
  Widget selectRootPage({required StatelessWidget homePage, required int appLastStableBuild});

}
