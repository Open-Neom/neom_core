import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/enums/auth_status.dart';

abstract class LoginService {

  Future<void> handleAuthChanged(User user);
  void setAuthStatus(AuthStatus status);
  AuthStatus getAuthStatus();

  Future<void> setAuthCredentials();
  AuthCredential? getAuthCredentials();
  Future<void> deleteFbaUser(AuthCredential credential);
  void setIsLoading(bool loading);

  Future<void> appleLogin();
  Future<void> googleLogin();
  Future<void> emailLogin();

  Future<void> signOut();
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey);

  Future<void> verifyPhoneNumber(String phoneNumber);
  Future<bool> validateSmsCode(String smsCode);
  void setIsPhoneAuth(bool value);
}
